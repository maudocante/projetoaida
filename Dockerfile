FROM nextcloud:latest
LABEL maudo cante <ummominhafilha@gmail.com>

COPY ./mkcert /mkcert 
RUN cd / && chmod +x /mkcert 
RUN cd / && ./mkcert -install && ./mkcert  gabiutente.gw localhost 127.0.0.1 && cp ./gabiutente.gw+2.pem /etc/ssl/certs/ssl-cert-snakeoil.pem && cp ./gabiutente.gw+2-key.pem \
/etc/ssl/private/ssl-cert-snakeoil.key 

RUN cd /etc/apache2/sites-available/ && sed -i '/DocumentRoot \/var\/www\/html/ a\ \tRedirect Permanent \/ https://cante.local' 000-default.conf
RUN sed -i '/DocumentRoot/a \\t\t<IfModule mod_headers.c>\n\t\t\tHeader always set Strict-Transport-Security "max-age=15552000; includeSubDomains"\n\t\t</IfModule>' /etc/apache2/sites-available/default-ssl.conf
RUN a2enmod rewrite
RUN a2ensite default-ssl
RUN a2enmod ssl

EXPOSE 80
EXPOSE 443
