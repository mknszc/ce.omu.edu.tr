# Bölüm sitesinin yönetim ve bakım kılavuzu

Bilgisayar Mühendisliği Bölümü Web Sayfalarını kurmak için:

- TODO

### Statik ce.omu.edu.tr dalının kurulması

Depoda `master` dalındaki `README.md`'yi okuyun.

### Wordpress Kurulumu

- wordpress'i güncel tutmak için git depolarından klonluyoruz. Bu da `/opt` altında konuşlandırılır.

        $ cd /opt
        $ sudo git clone git://github.com/dxw/wordpress.git wp

- `/opt/wp` de `/srv/www/ce.omu.edu.tr/site/a` 'ya bağlanır.

- uygun mysql kullanıcısı ve veritabanı oluşturulur.

- `/opt/wp` 'ye giderek `wp-config.php` dosyasında gerekli yerlere mysql kullanıcı adı, veritabanı adı ve parola yazdıldıktan sonra şu link tarayıcıda çalıştırılır. `http://site-adresi/wp-admin/install.php`. Ekrana gelen form istekler doğrultusunda doldurulur.

### Nginx Yapılandırması

- `/etc/nginx/sites-available` altına bil.omu.edu.tr adında dosya açılıp alttaki ayarlar yazılmalıdır.

- `/etc/nginx/sites-enabled` altına oluşturulan bu dosyaya sembolik link
  oluşturulur.

        server {
                listen 80;
                server_name .bil.omu.edu.tr;

                include base.conf;

                location /a/ {
                        expires 30d;
                        access_log off;
                        try_files $uri $uri/ /a/index.php?q=$uri&$args;
                }

                # gerçek dizin adreslerini vermemek için alttaki aliaslar tanımlandı...
                location /static {
                        alias /srv/www/$host/src/static;
                }
                location /asset {
                        alias /srv/www/$host/src/asset;
                }
                location /ders {
                        alias /srv/www/$host/src/static/ders;
                }
                # alttaki ayar ders içerikleri için
                rewrite ^/(bil[0-9][0-9]+)/*$ /ders/$1 redirect;

                # bundan sonraki ayarlar test bölümü için
                location /test/ {
                        expires 30d;
                        access_log off;
                        try_files $uri $uri/ /test/index.php?q=$uri&$args;
                }
        }

        server {
                listen 443;
                server_name .bil.omu.edu.tr;

                include base.conf;

                ssl on;
                ssl_certificate /etc/ssl/private/star_omu_edu_tr.crt;
                ssl_certificate_key /etc/ssl/private/star_omu_edu_tr.key;


                location /a/ {
                        expires 30d;
                        access_log off;
                        try_files $uri $uri/ /a/index.php?q=$uri&$args;
                }

                location /static {
                        alias /srv/www/$host/src/static;
                }
                location /asset {
                        alias /srv/www/$host/src/asset;
                }
                location /ders {
                        alias /srv/www/$host/src/static/ders;
                }
                rewrite ^/(bil[0-9][0-9]+)/*$ /ders/$1 redirect;

                location /test/ {
                        expires 30d;
                        access_log off;
                        try_files $uri $uri/ /test/index.php?q=$uri&$args;
                }
        }

### Permalink Ayarları

- admin panelinden: settings -> permalinks -> custom structure kısmına şu yazılır:

        /%year%%monthnum%/%postname%/

# Test (staging) sitesinin hazırlanışı

- `/opt/wp` 'nin `/opt/wp_t` adında kopyası oluşturulur.

- `/etc/nginx/sites-available` 'da bulunan `bil.omu.edu.tr` dosyasında uygun yere şu kısım eklenir.

        location /test/ {
                expires 30d;
                access_log off;
                try_files $uri $uri/ /test/index.php?q=$uri&$args;
        }

- mevcut sitenin yedeği alınır.

        mysqldump -u <kullanici_adi> <database_ismi> -p > yedek.sql

- yeni bir kullanıcı,veritabanı çifti oluşturulur ve yedeği içe aktarılır.

        mysql -u <yeni_kullanici_adi> <yeni_database_ismi> -p < yedek.sql

- `/opt/wp_t` altındaki `wp-config.php` 'de yeni kullanıcı ve yeni veritabanı ismi öncekilerle yer değiştirir.

- `/opt/wp_t` altındaki `wp-login.php` dosyasını açıp `require( dirname(__FILE__) . '/wp-load.php' );` bu satırın altına şu satırları yazmak gereklidir:

        update_option('siteurl', 'http://bil.omu.edu.tr/test' );
        update_option('home', 'http://bil.omu.edu.tr/test' );

bunları yazdıktan sonra, şu adresi tarayıcıdan çağırmak gerekir:

        http://bil.omu.edu.tr/test/wp-login.php

`wp-login.php` 'de yazılan satırları bu işlemleri yaptıktan sonra silmek gerekiyor. yani tek seferlik yapılıyor bu değişiklik.

### Tema Kurulumu

- mevcut durumda bulunan division teması github'a private depo olarak konur.

- bu depo `/opt` altına `division` adıyla klon edilir.

- `/opt/division` `/srv/www/ce.omu.edu.tr/a/wp-content/themes` altına sembolik linkle bağlanır.

### Temadaki Değişiklik

- temanın, wordpress 3.0 ve üzeri  sürümleri için şu ayar yapılmalıdır.

1) `/opt/division/functions/theme-options.php` dosyası açılır ve şu değişiklik yapılır:

       bunun yerine:  $modsname = 'mods_'.$theme;
       bu yazılmalı: $modsname = 'theme_mods_'.$theme;

2) daha sonra tarayıcıdan admin paneline girilir.

3) sol menünün en altında division yazan sekmeye gelinir.

4) theme options'a gidilir.

5) reset to defaults

6) save changes

### Temaya Kod Entegrasyonu

- tarayıcıdan admin paneline girilir.

- Sol altta Division -> Theme Options -> Code Integration kısmı açılır. Ayarlar şu şekilde olmalı:

Enable head code: Yes

Add code to the `<head>` of your site:

        <link
        href="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8/themes/base/jquery-ui.css"
        rel="stylesheet" type="text/css"/>
        <link rel="stylesheet" type="text/css" media="screen"
        href="/asset/tablecloth/tablecloth.css" />
        <script type="text/javascript"
        src="/asset/tablecloth/tablecloth.js"></script>
        <link rel="stylesheet" type="text/css" media="all"
        href="/asset/local.css" />
          <script>
          $(document).ready(function() {
            $("#accordion").accordion({
            collapsible: true,
            autoHeight: false,
            active: true
        });
          });
          </script>

Enable body code: Yes

Add code to the `<body>` (good tracking codes such as google analytics):

        <script type="text/javascript">

          var _gaq = _gaq || [];
          _gaq.push(['_setAccount', 'UA-22856640-1']);
          _gaq.push(['_trackPageview']);

          (function() {
            var ga = document.createElement('script'); ga.type =
            'text/javascript'; ga.async = true;
            ga.src = ('https:' == document.location.protocol ? 'https://ssl' :
            'http://www') + '.google-analytics.com/ga.js';
            var s = document.getElementsByTagName('script')[0];
            s.parentNode.insertBefore(ga, s);
          })();

### Kişi Sayfasındaki Resimler

- Resimlerin thumbnail türü 128x128 PNG olmalı.  Eğer elinizdeki resim bu
  şekilde bir kare değilse önce kare haline getirin (aksi halde ölçekleme
  sırasında bozulur).  Bu işlemden sonra `convert` ile resmi ölçekleyin:

        convert -resize 128 roktas_buyuk_boy.png roktas.png

- Resmi mutlaka `pngnq` ile optimize edin.

- Her şey tamamsa resmi `static/image/kisi` dizinine eposta adıyla kopyalayın.
  Örneğin eposta adresi `roktas@bil.omu.edu.tr` olan bir kişinin resmi
  `roktas.png` olmalı.

### Takvim Sayfası

- wordpress'in admin panelinden takvim adında yeni bir sayfa oluşturulur ve içerisine şu kod eklenir.

        <center><img src="/asset/load.gif" /></center>
        <iframe src="https://www.google.com/calendar/embed?showTitle=0&amp;mode=AGENDA&amp;height=600&amp;wkst=1&amp;bgcolor=%23FFFFFF&amp;src=takvim%40bil.omu.edu.tr&amp;color=%23711616&amp;ctz=Europe%2FIstanbul" style=" border-width:0; margin-top:-90px;" width="900" height="700" frameborder="0" scrolling="no"></iframe>

- Yukarıdaki takvim kodu takvim@bil adresinin takviminden üretilmiştir.

- `<center><img src="/asset/load.gif" /></center>` bu kısım ise takvim yükleninceye kadar ekranda animasyon göstermesini sağlar.

- iframe tag'ının stil özelliklerindeki `margin-top:-90px` sayfa yüklenince animasyonun üzerine gelmesini sağlar.
