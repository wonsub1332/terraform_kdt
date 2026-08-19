#!/bin/bash
        yum -y install httpd 
        sed -i 's/Listen 80/Listen ${var.server_port}/' /etc/httpd/conf/httpd.conf
        systemctl enable httpd
        systemctl restart httpd
        echo '<html><h1>Hello From Your Linux Web Server running on port ${var.server_port} </h1></html>' > /var/www/html/index.html
