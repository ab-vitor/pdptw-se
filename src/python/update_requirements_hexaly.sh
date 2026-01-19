# 1. Get Hexaly version
HEXALY_VERSION=$(pip show hexaly | grep Version | awk '{print $2}')

# 2. Write requirements-hexaly.txt automatically
echo "--index-url https://pip.hexaly.com" > requirements-hexaly.txt
echo "hexaly==$HEXALY_VERSION" >> requirements-hexaly.txt
