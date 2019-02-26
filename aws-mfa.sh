#!/bin/bash

set -eu

usage () {
    cat <<EOF
$0: simple script to automate session token from mfa
Usage: $0 [-p profilename] [-t temporary_profile_name] [-n arn] [-c authcode]
Options:
- p: AWS profile in ~/.aws/credentials. Default \`default\`.
- t: Temporary aws profile to create. Default \`tmp\`.
- n: IAM user arn. If not specified, read from stdin.
- c: Auth code generated by mfa token device. If not specified, read from stdin.
- r: Default region. Default \`ap-northeast-1\`
EOF
}

PROFILE=default
TMP_PROFILE=tmp
IAM_MFR_ARN=""
AUTHCODE=""
DEFAULT_REGION="ap-northeast-1"

while getopts ":p:t:n:c:r:h" opt; do
    case "$opt" in
        p)
            PROFILE=$OPTARG
            ;;
        t)
            TMP_PROFILE=$OPTARG
            ;;
        n)
            IAM_MFR_ARN=$OPTARG
            ;;
        c)
            AUTHCODE=$OPTARG
            ;;
        r)
            DEFAULT_REGION=$OPTARG
            ;;
        :|h|*)
            usage
            exit 1
            ;;
    esac
done

echo "Using \`$PROFILE\` profile"

if [ -z "$IAM_MFR_ARN" ]; then
    echo -n "Type MFA ARN: "
    read -r IAM_MFR_ARN
fi

if [ -z "$AUTHCODE" ]; then
    echo -n "Type MFA authcode: "
    read -r AUTHCODE
fi

response=$(aws --profile="$PROFILE" sts get-session-token --serial-number "$IAM_MFR_ARN" --token-code "$AUTHCODE")

aws --profile="$TMP_PROFILE" configure set default.region "$DEFAULT_REGION"
aws --profile="$TMP_PROFILE" configure set aws_access_key_id "$(echo "$response" | jq -r .Credentials.AccessKeyId)"
aws --profile="$TMP_PROFILE" configure set aws_secret_access_key "$(echo "$response" | jq -r .Credentials.SecretAccessKey)"
aws --profile="$TMP_PROFILE" configure set aws_session_token "$(echo "$response" | jq -r .Credentials.SessionToken)"

echo "Successfully saved aws credential as profile \"$TMP_PROFILE\""
