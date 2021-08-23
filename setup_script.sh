#!/bin/bash
echo "Hello, World (from my linode)" > index.html
nohup busybox httpd -f -p 80 &