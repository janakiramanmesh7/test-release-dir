set -e
owner="${owner:-}"
tag="${tag:-}"
repo="${repo:-}"
github_api_token="${github_api_token:-}"
filename="${filename:-}"

function print_help {
    echo "Script usage: $0 -o owner -t tag -r repo -f file -g token"
    echo "For more detailed help please refer to the README.md"
}

while getopts "h:o:r:t:g:f:" o; do
    case "${o}" in
        h)
            print_help
            exit 0
            ;;
        o)
            owner=${OPTARG}
            ;;
        r)
            repo=${OPTARG}
            ;;
        t)
            tag=${OPTARG}
            ;;
        g)
            github_api_token=${OPTARG}
            ;;
        f)
            filename=${OPTARG}
            ;;
        *)
           print_help
           exit 1
           ;;
        esac
      done

if [[ -z $owner ]] || [[ -z $repo ]] || [[ -z $tag ]] || [[ -z $github_api_token ]];then
    echo "variables missing"
    exit 1
fi

# Define variables.
GH_API="https://api.github.com"
GH_REPO="$GH_API/repos/$owner/$repo"
GH_TAGS="$GH_REPO/releases/tags/$tag"
AUTH="Authorization: token $github_api_token"
WGET_ARGS="--content-disposition --auth-no-challenge --no-cookie"
CURL_ARGS="-LJO#"

API_JSON=$(printf '{"tag_name": "%s","target_commitish": "master","name": "%s","body": "Release of version %s","draft": false,"prerelease": false}' $tag $tag $tag)
curl -XPOST --data "$API_JSON" https://api.github.com/repos/$owner/$repo/releases?access_token=$github_api_token

# Validate token.
curl -o /dev/null -sH "$AUTH" $GH_REPO || { echo "Error: Invalid repo, token or network issue!";  exit 1; }

# Read asset tags.
response=$(curl -sH "$AUTH" $GH_TAGS)
echo "$respone"
# Get ID of the asset based on given filename.
eval $(echo "$response" | grep -m 1 "id.:" | grep -w id | tr : = | tr -cd '[[:alnum:]]=')
[ "$id" ] || { echo "Error: Failed to get release id for tag: $tag"; echo "$response" | awk 'length($0)<100' >&2; exit 1; }

# Upload asset
echo "Uploading asset... "

# Construct url
GH_ASSET="https://uploads.github.com/repos/$owner/$repo/releases/$id/assets?name=$(basename $filename)"

curl -s "$AUTH" --data-binary @"$filename" -H "Authorization: token $github_api_token" -H "Content-Type: application/octet-stream" $GH_ASSET

