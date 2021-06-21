#!/bin/bash
yum -y update
yum -y install httpd
myip = `curl http://169.254.169.254/latest/meta-data/local-ipv4`
echo "<h2>WebServer with IP: $myip</h2><br>Build by Terraform using external script!" 

cat <<EOF > /var/www/html/index.html
<html>
<body>
</h2><br>Build by Terraform <font color="red"> v0.12"</font> with dynamic external files!" </h2></br>
<font color="green">Server PrivateIP: <font color = "aqua">$myip<br><br>

<font colot="magenta">
<b>Version 2.0</b>
</body>
</html>
EOF

sudo service httpd restart
chconfig httpd on