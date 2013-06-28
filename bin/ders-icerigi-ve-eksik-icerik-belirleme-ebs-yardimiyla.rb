#!/usr/bin/env ruby
# encoding: UTF-8
#
# UBS'de girilen içerik EBS üzerinden webde görülebilmektedir. Bu betik
# yardımıyla Bilgisayar Mühendisliği Bölümü'ne ait tüm derslerin içerik tek bir
# html dosya olarak üretilmektedir. Ayrıca içeriği eksik olan derslere ait
# raporlar üretilmektedir.
#
# Usage:
#   $ ruby ders-icerigi-ve-eksik-icerik-belirleme-ebs-yardimiyla.rb
#
# Note:
#   EBS arayüzü değiştirilirse BASE_URL altında ki `uri`'yi kontrol ederek
#   başlamak gerek, değişikliğe.

require 'nokogiri'
require 'open-uri'
require 'pp'
require 'csv'
require 'roman_numerals_converter'
require 'roo'

class String
  def is_i?
    !!(self =~ /^[-+]?[0-9]+$/)
  end
end

$course_keys = ['level', 'objective', 'lecture', 'outcomes', 'delivery',
        'prerequisities', 'component', 'reading', 'learning',
        'language', 'work', 'content', 'detailed_content',
        'assessment', 'workload']

# EBS'den ders bilgilerini cekip hash'e koyar
#
# Usage:
#   d = get_course_info(doc)
#   p d['code']
def get_course_info(doc)
  keys = ['code', 'name', 'type', 'year', 'term', 'ects']

  info = {}
  doc.css('.AltSatir > td').each_with_index do |d, i|
    info[keys[i]] = d.content
  end
  info
end

# EBS'den ders ayrintilarini cekip hash'e koyar
#
# Usage:
#   d = get_course_detail(doc)
#   p d['content']
def get_course_detail(doc)
  detail = {}
  doc.css('#icerik .keyContainer .Value').each_with_index do |d, i|
    detail[$course_keys[i]] = d.content
  end
  detail
end

# EBS'den bolum derslerini cekip hash'e koyar
#
# Usage:
#   d = get_department_courses(doc)
#   p d['BİL121'][:ects]
def get_department_courses(doc)
  keys = ['link', 'name', 'type', 'theoretical', 'practice', 'laboratory', 'ects']

  courses = {}
  doc.css('.ptProgramTanimlari.section .ders').each_with_index do |d, i|
    code = d.at_xpath('td[1]/a/text()').content.strip.to_sym
    course = {uri:  d.at_xpath('td[1]/a')['href'],
              code: code,
              name: d.at_xpath('td[2]/text()').content,
              type: d.at_xpath('td[3]/text()').content,
              theoratical: d.at_xpath('td[4]/text()').content,
              practice: d.at_xpath('td[5]/text()').content,
              laboratory: d.at_xpath('td[6]/text()').content,
              ects: d.at_xpath('td[7]/text()').content }

    if courses.has_key?(code)
      courses[code] << course
    else
      courses[code] = [course]
    end
  end
  courses
end

# Dersin ilgili alaninda ki durumun CSV dosyada gosterilmesinde kullanilacak
# isaret donusturucu
def status2sign(status)
  status ? 'E' : 'H'
end

# Bir cok raporlama uretilir,
# 1. Ders icerigi
# 2. Ders eksiklik durumu
def report(uri, lang, ccmap, base_url, dnm4output)
  doc = Nokogiri::HTML(open(uri))
  courses = get_department_courses(doc)

  mufredat = {secmeli: {}, zorunlu: {}}
  course_status = {}
  mcode_status = {}

  courses.each do |ccode, ncourse|
    ncourse.each do |course|
      code = course[:code]
      cmap_code = code.to_s.is_i? ? code.to_s.to_i : code.to_s
      cmap = ccmap[cmap_code]
      mcode = cmap[:mufredat]

      p "Code: '#{mcode}' isleniyor..."
      uri = base_url + course[:uri]
      doc = Nokogiri::HTML(open(uri))

      info = get_course_info(doc)
      detail = get_course_detail(doc)

      # "YD101 Yabanci Dil" benzeri generic dersleri pas gec
      next if detail.empty?

      status = {final: (detail['objective'].empty? and detail['content'].empty? and detail['detailed_content'].empty?)}
      $course_keys.each do |k|
        status[k.to_sym] = !detail[k].empty?
      end

      if status[:final]
        course_status[code] ||= status
        next
      else
        course_status[code] = status
      end

      # Icerigi eksik dersleri "ders icerikleri" ciktisina koyma
      next if status[:final]

      # mufredat cikti dosyasina eklendi ise pas gec
      next if mcode_status.key? mcode
      mcode_status[mcode] = true

      t, p, l = course[:theoratical], course[:practice], course[:laboratory]
      name = info['name'].empty? ? cmap[:ad] : info['name']
      str = "<h4 id='#{mcode}'>#{mcode} #{cmap[:ad]} #{t}-#{p}-#{l} AKTS: #{info['ects']}</h4>\n"

      if status[:content]
        str += "<p>#{detail['content']}</p>"
      else
        # str += "<p>#{detail['objective']}</p>"
        str += "<p><font color='red'>EKSİK</font></p>"
      end

      str += "<div style='display: none;' class='stuff'>#{cmap[:hoca]}</div>" if ccmap.key? cmap_code
      str += "<div class='detail'>Dersle ilgili daha fazla ayrıntıya ulaşmak istiyorsanız <a href='#{uri}'>tıklayınız.</a></div>"

      # unless detail['reading'].empty?
      #   str += "<h4>Kaynaklar</h4>\n"
      #   str += "<p>#{detail['reading']}</p>"
      # end

      t = cmap[:yy]
      y = (t - 1)/2 + 1

      sz = (cmap[:sz].strip.downcase == "z") ? :zorunlu : :secmeli

      if mufredat[sz][y].nil?
        mufredat[sz][y] = {}
      end

      if mufredat[sz][y][t].nil?
        mufredat[sz][y][t] = "#{str}<hr>"
      else
        mufredat[sz][y][t] += "#{str}<hr>"
      end
    end
  end

  fnm = "#{dnm4output}courses_problematic_#{lang}.csv"
  CSV.open(fnm, 'w') do |csv|
    r = ['Code', 'Name']

    $course_keys.each do |k|
      r << k.to_s
    end

    csv << r

    course_status.each do |code, status|
      if status[:final]
        r = [code, courses[code][0][:name]]

        $course_keys.each do |k|
          r << status2sign(status[k.to_sym])
        end

        csv << r
      end
    end
  end
  p "Problemli dersler '#{fnm}' icerisine saklandi."

  fnm = "#{dnm4output}courses_status_#{lang}.csv"
  CSV.open(fnm, 'w') do |csv|
    r = ['Code', 'Name', 'Final']

    $course_keys.each do |k|
      r << k.to_s
    end

    csv << r

    course_status.each do |code, status|
      r = [code, courses[code][0][:name], status2sign(status[:final])]

      $course_keys.each do |k|
        r << status2sign(status[k.to_sym])
      end

      csv << r
    end
  end
  p "Bölümün tüm derslerinin durumu '#{fnm}' icerisine saklandi."

  # str = "<h1>OMÜ Bilgisayar Mühendisliği Bölümü</h1>"
  [:secmeli, :zorunlu].each do |sz|
    (1..8).each do |yy|
      y = (yy - 1)/2 + 1

      next if mufredat[sz][y].nil? or mufredat[sz][y][yy].nil?

      fnm = "#{dnm4output}ders_icerikleri_#{lang}_#{sz.to_s}_#{yy}.html"
      fp = File.new(fnm, 'w')

      str = "<h3 id='yy#{yy}'>#{yy.to_roman}. YARIYIL (#{yy%2==1 ? 'GÜZ' : 'BAHAR'} DÖNEMİ)</h3>"
      str += mufredat[sz][y][yy]

      fp.write(str)
      fp.close
      p "Ders icerikleri '#{fnm}' icerisine saklandi."
    end
  end

  fnm = "#{dnm4output}ders_icerikleri_#{lang}.html"
  fp = File.new(fnm, 'w')

  str = "<h1>OMÜ Bilgisayar Mühendisliği Bölümü</h1>"
  [:zorunlu, :secmeli].each do |sz|
    str += "<h2 id='secmeli'>SEÇMELİ DERSLER</h2>" if sz == :secmeli

    (1..8).each do |yy|
      y = (yy - 1)/2 + 1

      next if mufredat[sz][y].nil? or mufredat[sz][y][yy].nil?

      str += "<h3 id='yy#{yy}'>#{yy.to_roman}. YARIYIL (#{yy%2==1 ? 'GÜZ' : 'BAHAR'} DÖNEMİ)</h3>"
      str += mufredat[sz][y][yy]
    end
  end

  fp.write(str)
  fp.close
  p "Ders icerikleri '#{fnm}' icerisine saklandi."
end

def get_course_map(fnm4course_map)
  harita = {}
  CSV.foreach(fnm4course_map, headers: true, header_converters: :symbol, converters: :all) do |row|
    harita[row.fields[0]] = Hash[row.headers[1..-1].zip(row.fields[1..-1])]
  end
  harita
end

# Ana program
if __FILE__ == $0
  BASE_URL = 'http://ebs.omu.edu.tr/ebs/'
  OUTPUT_DIR = '/tmp/'
  COURSE_MAP_FILE = '../data/course_map.csv'

  uri_tr = BASE_URL + "program.php?dil=tr&mod=1&Program=2727&o=M%C3%9CHEND%C4%B0SL%C4%B0K+FAK%C3%9CLTES%C4%B0+%2F+B%C4%B0LG%C4%B0SAYAR+M%C3%9CHEND%C4%B0SL%C4%B0%C4%9E%C4%B0+B%C3%96L%C3%9CM%C3%9C"
  uri_en = BASE_URL + "program.php?dil=en&mod=1&Program=2727&o=FACULTY%20OF%20ENGINEERING%20/%20COMPUTER%20ENGINEERING"

  ccmap = get_course_map(COURSE_MAP_FILE)
  report(uri_tr, 'tr', ccmap, BASE_URL, OUTPUT_DIR)
  report(uri_en, 'en', ccmap, BASE_URL, OUTPUT_DIR)
end
