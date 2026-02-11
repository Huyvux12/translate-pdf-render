#!/bin/bash

# Generate users.txt from environment variable
# Format: AUTH_USERS="user1,pass1;user2,pass2"
if [ -n "$AUTH_USERS" ]; then
    echo "$AUTH_USERS" | tr ';' '\n' > /app/users.txt
    echo "[entrypoint] Authentication enabled with $(wc -l < /app/users.txt) user(s)"
    exec pdf2zh -i --serverport ${PORT:-7860} --authorized /app/users.txt
else
    echo "[entrypoint] WARNING: No AUTH_USERS set, running without authentication!"
    exec pdf2zh -i --serverport ${PORT:-7860}
fi
