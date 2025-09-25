*&---------------------------------------------------------------------*
*& Report ZAU_R_AFFINE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zau_r_affine.


*----------------------------------------------------------------------*
* constants
*----------------------------------------------------------------------*
CONSTANTS:
  gc_alphabet TYPE string VALUE 'abcdefghijklmnopqrstuvwxyz',
  gc_m        TYPE i      VALUE 26. "Alfabenin uzunluğu

*----------------------------------------------------------------------*
* Selection Screen
*----------------------------------------------------------------------*
PARAMETERS:
  p_text TYPE string LOWER CASE OBLIGATORY,  " İşlenecek Metin
  p_a    TYPE i OBLIGATORY,                  " a anahtarı
  p_b    TYPE i OBLIGATORY.                  " b anahtarı

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001. " İşlem Türü
PARAMETERS:
  p_encr RADIOBUTTON GROUP op DEFAULT 'X', " Şifrele
  p_decr RADIOBUTTON GROUP op.             " Şifre Çöz
SELECTION-SCREEN END OF BLOCK b1.

*----------------------------------------------------------------------*
* data definitions
*----------------------------------------------------------------------*
DATA:
  gv_input_text  TYPE string,
  gv_output_text TYPE string.

*----------------------------------------------------------------------*
* start - of - selection
*----------------------------------------------------------------------*
START-OF-SELECTION.

  " 1. Girdi Kontrolü: a ve m (26) aralarında asal mı?
  PERFORM check_coprime USING p_a gc_m.

  " 2. Metni işleme için hazırla (sadece küçük harfler ve rakamlar kalsın)
  gv_input_text = p_text.
  REPLACE ALL OCCURRENCES OF REGEX '[^a-z0-9]' IN gv_input_text WITH ''.

  " 3. Seçilen işleme göre yönlendir
  IF p_encr = 'X'.
    PERFORM encrypt_text.
  ELSE.
    PERFORM decrypt_text.
  ENDIF.

  " 4. Sonucu ekrana yazdır
  PERFORM display_result.

*&---------------------------------------------------------------------*
*& FORM check_coprime
*& a ve m'nin aralarında asal (coprime) olup olmadığını kontrol eder
*&---------------------------------------------------------------------*
FORM check_coprime USING iv_a TYPE i iv_m TYPE i.
  DATA: lv_gcd TYPE i.

  " EBOB hesapla
  PERFORM calculate_gcd USING iv_a iv_m CHANGING lv_gcd.

  " EBOB 1 değilse, aralarında asal değildir. Hata ver ve programı durdur.
  IF lv_gcd <> 1.
    MESSAGE |a ({ iv_a }) ve m ({ iv_m }) değerleri aralarında asal değil (EBOB={ lv_gcd }). Şifreleme yapılamaz.| TYPE 'E'.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& FORM encrypt_text
*& Metni şifreler: E(x) = (a * i + b) mod m
*&---------------------------------------------------------------------*
FORM encrypt_text.
  DATA: lv_len        TYPE i,
        lv_offset     TYPE i,
        lv_char       TYPE c,
        lv_char_index TYPE i,
        lv_new_index  TYPE i.

  lv_len = strlen( gv_input_text ).
  DO lv_len TIMES.
    lv_offset = sy-index - 1.
    lv_char = gv_input_text+lv_offset(1).

    " Karakter bir harf mi?
    IF lv_char CA gc_alphabet.
      " Harfin alfabedeki sırasını (index) bul (0-25)
      FIND lv_char IN gc_alphabet MATCH OFFSET lv_char_index.

      " Şifreleme formülünü uygula
      lv_new_index = ( p_a * lv_char_index + p_b ) MOD gc_m.

      " Sonuca yeni harfi ekle
      CONCATENATE gv_output_text gc_alphabet+lv_new_index(1) INTO gv_output_text.

      " Karakter bir rakam mı?
    ELSEIF lv_char CA '0123456789'.
      " Rakamları değiştirmeden sonuca ekle
      CONCATENATE gv_output_text lv_char INTO gv_output_text.
    ENDIF.
  ENDDO.
ENDFORM.

*&---------------------------------------------------------------------*
*& FORM decrypt_text
*& Metnin şifresini çözer: D(y) = a⁻¹ * (y - b) mod m
*&---------------------------------------------------------------------*
FORM decrypt_text.
  DATA: lv_len        TYPE i,
        lv_offset     TYPE i,
        lv_char       TYPE c,
        lv_char_index TYPE i,
        lv_new_index  TYPE i,
        lv_mmi        TYPE i, " Modüler Çarpma Tersi (MMI)
        lv_temp       TYPE i.

  " a'nın modüler tersini (a⁻¹) hesapla
  PERFORM calculate_mmi USING p_a gc_m CHANGING lv_mmi.

  lv_len = strlen( gv_input_text ).
  DO lv_len TIMES.
    lv_offset = sy-index - 1.
    lv_char = gv_input_text+lv_offset(1).

    " Karakter bir harf mi?
    IF lv_char CA gc_alphabet.
      " Harfin alfabedeki sırasını (index) bul (0-25)
      FIND lv_char IN gc_alphabet MATCH OFFSET lv_char_index.

      " Şifre çözme formülünü uygula
      " Önce (y-b) kısmını hesapla
      lv_temp = lv_char_index - p_b.

      " Sonra a⁻¹ ile çarp ve mod al
      lv_new_index = ( lv_mmi * lv_temp ) MOD gc_m.

      " ABAP'ta mod işlemi negatif sonuç verebilir, bunu düzeltmeliyiz.
      " Sonuç 0-25 aralığında olmalı.
      IF lv_new_index < 0.
        lv_new_index = lv_new_index + gc_m.
      ENDIF.

      " Sonuca orijinal harfi ekle
      CONCATENATE gv_output_text gc_alphabet+lv_new_index(1) INTO gv_output_text.

      " Karakter bir rakam mı?
    ELSEIF lv_char CA '0123456789'.
      " Rakamları değiştirmeden sonuca ekle
      CONCATENATE gv_output_text lv_char INTO gv_output_text.
    ENDIF.
  ENDDO.
ENDFORM.

*&---------------------------------------------------------------------*
*& FORM display_result
*& Sonucu ekrana yazdırır
*&---------------------------------------------------------------------*
FORM display_result.
  WRITE: / 'Orijinal Metin (işlenmiş):', gv_input_text.
  WRITE: / 'a anahtarı:', p_a.
  WRITE: / 'b anahtarı:', p_b.
  ULINE.
  IF p_encr = 'X'.
    WRITE: / 'Şifrelenmiş Sonuç:'.
  ELSE.
    WRITE: / 'Çözülmüş Sonuç:'.
  ENDIF.
  WRITE: gv_output_text.
ENDFORM.

*&---------------------------------------------------------------------*
*& YARDIMCI RUTİNLER
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& FORM calculate_gcd
*& Öklid algoritması ile En Büyük Ortak Bölen'i (EBOB/GCD) hesaplar
*&---------------------------------------------------------------------*
FORM calculate_gcd USING iv_val1 TYPE i iv_val2 TYPE i CHANGING cv_gcd TYPE i.
  DATA: lv_a TYPE i,
        lv_b TYPE i,
        lv_t TYPE i.

  lv_a = iv_val1.
  lv_b = iv_val2.

  WHILE lv_b <> 0.
    lv_t = lv_b.
    lv_b = lv_a MOD lv_b.
    lv_a = lv_t.
  ENDWHILE.

  cv_gcd = lv_a.
ENDFORM.

*&---------------------------------------------------------------------*
*& FORM calculate_mmi
*& a'nın m modülüne göre Modüler Çarpma Tersini (MMI) bulur
*& (a * x) mod m = 1 koşulunu sağlayan x'i bulur.
*&---------------------------------------------------------------------*
FORM calculate_mmi USING iv_a TYPE i iv_m TYPE i CHANGING cv_mmi TYPE i.
  DATA: lv_x TYPE i.

  DO iv_m TIMES.
    lv_x = sy-index.
    IF ( iv_a * lv_x ) MOD iv_m = 1.
      cv_mmi = lv_x.
      EXIT.
    ENDIF.
  ENDDO.
ENDFORM.
