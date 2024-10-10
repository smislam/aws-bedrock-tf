rm -rf files/
cd lambda
rm -rf dist/
npm i && npm run build
mkdir dist
mv *.js dist/
cp -r ./node_modules dist/
cd ..
terraform apply -input=false -auto-approve