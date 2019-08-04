# docker-magento2
Dockerfile for Magento 2 running on Apache 2 server with PHP 7.2
Image is available at https://cloud.docker.com/repository/docker/abhinavchawla13/magento2-apache2-php7.2-dev


This image is only for *testing* and *trying* out. Do *NOT* use it for development and production. Use the Dockerfile and instructions below to create your own image.

___This is important because the current image has an installed functioning Magento instance running on my private AWS dummy database.___


## Build instructions
1. Inside the *Dockerfile*, update the MySQL envirnment variables (`MYSQL_HOST`, `MYSQL_USER`, `MYSQL_PASSWORD` and `MYSQL_DATABASE`).
2. Update *auth.json* with the public and private keys from your Magento account (or create a new account at https://marketplace.magento.com/ and generate new set of keys) into the username and password fields respectively.
3. 
```
cd REPO_DIRECTORY
docker build -t magento2-apache2-php7.2 .
```

This will build an docker image with the name **magento2-apache2-php7.2**. 

## Running the image
```
docker run -p 8086:80 -d magento2-apache2-php7.2
```
Ensure that the port passed with the `docker run` command is `8086:80`.<br>
**80** is the port apache is exposing.<br>
**8086** is the port where Magento is running on the image, so it will be easier to access it at the same port on your localhost.

You can find both these values in the Dockerfile, and can update so accordingly, if need be. 

After the command is run succesfully, you would be able to access the Magento on your system by reaching the address `localhost:8086`, and the admin portal at `localhost:8086/admin` (defined by `MAGENTO_BACKEND_FRONTNAME` in the Dockerfile). 

## Installation path
Magento2 will be installed at `var\www\html`, which is also the folder exposed by Apache.

## Notes
You learn how to setup Magento2 on your laptop locally from the tutorial here: https://cloudkul.com/blog/magento2-installation-mac-os/<br>
I used the installation with Composer option, and so does the Dockerfile.

We require database credentials in our Dockerfile (which can be sourced in from external file and added into environment when building the image for safer process builds). As we are installing Magento into our image, Magento requires a database as part of its installation. (More information at https://devdocs.magento.com/guides/v2.3/install-gde/install/cli/install-cli-install.html)

Once the installation is complete, and you can `exec` into the image, and update the database configuration for Magento by updating the file at `/var/www/html/app/etc/env.php`. <br>
After updating, remember to index by using the following command in the Magento installation path:<br>
```
php bin/magento indexer:reindex
```
Also, you can use the next command to compile the code:
```
php bin/magento setup:di:compile;
```

### Few issues
MAMP: If the default ports do not work, you can try using port 80 for Apache and 3306 for MySQL.

Make sure all the permissions are provided to Magento folders to execute (you can find the following commands in the Dockerfile):
```
chown -R www-data:www-data /var/www/html/ 
chmod 777 -R /var/www/html/var
chmod 777 -R /var/www/html/generated
chmod 777 -R /var/www/html/app/etc
```

If the image fails on the Magento installing command, it _most likely_ could be a database issue, especially if authentication is correctly placed in auth.json. One of the errors you could receive is:<br>
`error 3098 (hy000) at line : the table does not comply with the requirements by an external plugin.`<br>
This might have happene because the database might have group replication on. I ended up using a AWS Database for this project.
