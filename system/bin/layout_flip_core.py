#!/usr/bin/env python3
import os, sys
EN = "`qwertyuiop[]asdfghjkl;'zxcvbnm,./~QWERTYUIOP{}ASDFGHJKL:\"ZXCVBNM<>?"
RU = "ёйцукенгшщзхъфывапролджэячсмитьбю.ЁЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,"
en2ru, ru2en = str.maketrans(EN, RU), str.maketrans(RU, EN)
en_set, ru_set = set(EN), set(RU)
text = sys.stdin.read()
en = ru = 0
for ch in text:
    ie, ir = ch in en_set, ch in ru_set
    if ie and not ir: en += 1
    elif ir and not ie: ru += 1
if ru > en: out = text.translate(ru2en)
elif en > ru: out = text.translate(en2ru)
elif ru: out = text.translate(ru2en)
else: out = text.translate(en2ru)
sys.stdout.write(out)
