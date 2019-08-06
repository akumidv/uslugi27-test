#!/bin/bash
baseEmail="test@test.ru"
reserveEmail="second@domen.com"

emailText=""
failurl=""
error=0
header="User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.89 Safari/537.36"
urlList=`curl -L -H $header -s -k https://uslugi27.ru | 
   grep -oP "href=\"*[a-zA-Z0-9/:\-_\.\?@=&%]+\"*" |
   grep -vE "javascript:void|tel:|open27.ru|mailto:|vk.com|twitter.com|t.me|facebook.com|odnoklassniki.ru|banner.sx\?id=10510128" |
   sed "s/https:\/\/uslugi27.ru//" |
   sed "s/href=\"\//href=\"/" | 
   sed "s/href=\"//" | sed "s/\"//"`

for i in ${urlList[@]}
do
#  check_res=`curl -L -H "$header" "https://uslugi27.ru/$1"`
  check_status=`curl -L -H "$header" -s -k -w %{http_code} -o /dev/null https://uslugi27.ru/${i}`
  echo "$check_status url=$i"
#  sleep 1
  echo "$i" | grep -E "service.htm|banner.sx" > /dev/null
  if [[ $check_status == 200 && $? -eq 0 ]]; then
    res=`curl -L -H "$header" -s -k "https://uslugi27.ru/${i}"`
    echo $res | grep -o "location.replace('/error404.htm')" > /dev/null
    if [ $? -eq 0 ]; then
      echo " 	 404 (location => error404)"
      error=1
      emailText="404 url=$i\n$emailText"
      failurl="404 url=https://uslugi27.ru/$i\n$failurl"
    else 
      echo "  ok check (location => error404)"
      emailText="$check_status url=https://uslugi27.ru/$i\n$emailText"
    fi
  elif [ $check_status -ne 200 ]; then
    emailText="$check_status url=https://uslugi27.ru/$i\n$email"
    failurl="$check_status url=https://uslugi27.ru/$i\n$failurl"
    error=1
  else
    emailText="$check_status url=https://uslugi27.ru/$i\n$emailText"
  fi
done

if [ $error -eq 1 ]; then
  if [ -n $baseEmail ]; then echo -ne "To:$baseEmail\nSubject:uslugi27 - FAIL\n\nFAIL\n$failurl\n\nALL\n$emailText\n" | ssmtp -t; fi
  if [ -n $reserveEmail ]; then echo -ne "To:$reserveEmail\nSubject:uslugi27 - FAIL\n\nFAIL\n$failurl\n\nALL\n$emailText\n" | ssmtp -t; fi

else
  if [ -n $baseEmail ]; then echo -ne "To:$baseEmail\nSubject:uslugi27 - OK\n\n$emailText\n" | ssmtp -t; fi
  if [ -n $reserveEmail ]; then echo -ne "To:$reserveEmail\nSubject:uslugi27 - OK\n\n$emailText\n" | ssmtp -t; fi
fi
