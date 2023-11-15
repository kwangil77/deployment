#!/bin/bash
%{ if substr(instance_type, 0, 3) == "mac" }
curl -s -o /tmp/bootstrap.sh https://....s3.ap-northeast-2.amazonaws.com/.../bootstrap.sh
%{ else }
wget -P /tmp/ https://....s3.ap-northeast-2.amazonaws.com/.../bootstrap.sh
%{ endif }
sh /tmp/bootstrap.sh