#!/bin/bash

yum -y install httpd

systemctl enable httpd
systemctl restart httpd

cat <<'EOF' > /var/www/html/index.html
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>Web Server Test</title>

    <style>
        body {
            margin: 0;
            height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            font-family: Arial, sans-serif;
            background-color: #f4f6f8;
        }

        .container {
            text-align: center;
            background-color: white;
            padding: 50px 70px;
            border-radius: 12px;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
        }

        h1 {
            color: #232f3e;
            margin-bottom: 10px;
        }

        .status {
            color: #16a34a;
            font-weight: bold;
            font-size: 20px;
        }

        .info {
            margin-top: 20px;
            color: #666;
        }
    </style>
</head>

<body>

    <div class="container">
        <h1>Web Server Test</h1>

        <p class="status">
            ● Server is running
        </p>

        <p class="info">
            Apache Web Server
        </p>
    </div>

</body>
</html>
EOF

systemctl restart httpd