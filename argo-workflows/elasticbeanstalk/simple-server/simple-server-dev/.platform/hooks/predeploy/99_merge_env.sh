#!/bin/bash
sed -E 's/.*=/\U&/g' /etc/aws-meta.env >> .env