#!/usr/bin/env python
# -*- codding: utf-8 -*-

import sys

try:
        if sys.argv[1] != '':
                archivo = sys.argv[1]
except:
        print 'Debe indicar el nombre de un archivo: pyvoca.py [archivo]'
        sys.exit(0)


fr = open(archivo, 'r')
fw = open(archivo+'_voca', 'w')
contador = 0
for linea in fr.xreadlines():
	palabra = ''
	for letra in linea:
		if letra != ' ' and letra != '.' and letra != ',' and letra != '\n':
			if letra.isdigit() == False:
				palabra = palabra + letra
	palabra = palabra.strip()
	contador += 1
	fw.write(palabra+'\n')
print 'Escritas '+str(contador)+' palabras en '+archivo+'_voca'
fw.close()
fr.close()
