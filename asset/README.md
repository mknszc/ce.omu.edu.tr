## İkon Üretimi

- Bir ikon paketi seç ve kur.   Örneğin `tango-icon-theme`.

- İlgili temada SVG ikonların bulunduğu dizine geç ve SVG ikon seç.

        cd  /usr/share/icons/Tango/scalable/

- Seçilen SVG dosyalardan inkscape ile PNG üret.  Divison temasında `80x80`
  boyutlu ikonlar kullanılıyor.  O halde:

        inkscape -e bu-guzel.png -w 80 bu-guzel.svg

- PNG'yi optimize et, `pngnq` ile:

        pngnq bu-guzel.png # bu-guzel-nq8.png üretir
        mv bu-guzel-nq8.png bu-guzel.png
