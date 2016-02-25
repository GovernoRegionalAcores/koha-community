# Koha community

## About

- MySQL is not included in this image;
- Unimarc flavour is installed;
- Portuguese locale is installed;
- Intranet is using port 8080 and OPAC is using port 8081

## Usage

docker run -d --link your_mysql_container:mysql -p 8080:8080 -p 8081:8081 governoregionalazores/koha-community

