#/bin/bash

BASE=/Users/miguoliang/Documents/Projects/QYResearch/website-backend/src/main/java/com/qyresearch/website/router;
DEST=/Users/miguoliang/Documents/Projects/QYResearch/website-frontend/src/app/api/;
BASE_URL=https://sandbox.muchencute.com/qyresearch-website-backend/api/;

for i in `ls $BASE`; do

	echo $i;

	FILENAME=`echo "$i" | sed 's/Router.java//g' | sed 's/\([a-z]\)\([A-Z]\)/\1-\2/g' | tr '[A-Z]' '[a-z]'`;
	`node backend2AngularHttpService.js $BASE/$i $BASE_URL > $DEST/$FILENAME.service.ts`;

done;
