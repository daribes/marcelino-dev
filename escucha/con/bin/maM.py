#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Este script sirve para crear un archivo de correspondecia fonetica 
# desde un archivo cualquiera que tenga una sola palabra por linea

import sys

try:
	if sys.argv[1] != '':
		archivo = sys.argv[1]
except:
	print 'Debe indicar el nombre de un archivo: maM.py archivo.txt'
	sys.exit(0)

fr = open(sys.argv[1], 'r')
print '\nArchivo '+sys.argv[1]+' abierto'

contador = 0
for linea in fr.xreadlines():
	contador += 1
print 'El archivo '+archivo+' contiene '+str(contador)+' lineas'
fr.close()

fw = open('salida.dict', 'w')
fr = open(sys.argv[1], 'r')
contador = 0
for linea in fr.xreadlines():
	letra = ''
	cletra = 0
	palabra = ''
	for letra in linea:
		if letra != ' ' and letra != '\n':
			palabra = palabra + letra
			cletra += 1
		else:
			break
	cletra = 0
	ppalabra = ''
	while cletra < len(palabra):
		eletra = True
		if palabra[cletra] == '\xc3':
			if palabra[cletra+1] == '\xb1':
				letra = '\xc3\xb1'
				eletra = False
				cletra += 1
			elif palabra[cletra+1] =='\xa1':
				letra = 'a'
				eletra = False
				cletra += 1
			elif palabra[cletra+1] =='\xa9':
                                letra = 'e'
                                eletra = False
				cletra += 1
			elif palabra[cletra+1] =='\xad':
                                letra = 'i'
                                eletra = False
				cletra += 1
			elif palabra[cletra+1] =='\xb3':
                                letra = 'o'
                                eletra = False
				cletra += 1
			elif palabra[cletra+1] =='\xba':
                                letra = 'u'
                                eletra = False
				cletra += 1
		if eletra == True:
			letra = palabra[cletra]
		ppalabra = ppalabra + letra
		cletra += 1
	palabra = ppalabra
# aqui vamos a decodificar la fonetica ---------------
# a b c   ch d e f g h i j k l ll m n ñ  o p qu r    rr s t u v w x y z
# a b k/z ch d e f g   i j k l ll m n gn o p k  r/rr rr s t u b u x y z
	fonetica = ' '
	fonema = ''
	cletra = 0
	while cletra < len(palabra):
		eletra = True
		if palabra[cletra] == 'c':
			if cletra < len(palabra)-1:
				if palabra[cletra+1] == 'e' or palabra[cletra+1] == 'i':
					fonema = 'z'
					eletra = False
				else:
					if palabra[cletra+1] == 'h':
						fonema = 'ch'
						eletra = False
						cletra += 1
					else:
						fonema = 'k'
						eletra = False
			else:
				fonema = 'k'
				eletra = False
		elif palabra[cletra] == 'y':
			if cletra == len(palabra)-1:
				fonema = 'i'
				eletra = False
			else:
				fonema = 'y'
				eletra = False
		elif palabra[cletra] == 'g':
			if cletra < len(palabra)-2:
				if palabra[cletra+2] == 'i' or palabra[cletra+2] == 'e':
					fonema = 'g'
					eletra = False
					cletra += 1
				else:
					fonema = 'g'
					eletra = False
		elif palabra[cletra] == 'h':
			fonema = ''
			eletra = False
		elif palabra[cletra] == 'l':
			if cletra < len(palabra)-1:
				if palabra[cletra+1] == 'l':
					fonema = 'll'
					eletra = False
					cletra += 1
				else:
					fonema = 'l'
					eletra = False
			else:
				fonema = 'l'
				eletra = False
		elif palabra[cletra] == '\xc3':
			if cletra < len(palabra)-1:
				if palabra[cletra+1] == '\xb1':
					fonema = 'gn'
					eletra = False
					cletra += 1
		elif palabra[cletra] == 'q':
			if cletra < len(palabra)-1:
				if palabra[cletra+1] == 'u':
					fonema = 'k'
					eletra = False
					cletra += 1
                elif palabra[cletra] == 'v':
                        fonema = 'b'
                        eletra = False
                elif palabra[cletra] == 'w':
                        fonema = 'u'
                        eletra = False
		elif cletra == 0:
			if palabra[cletra] == 'r':
				fonema = 'rr'
				eletra = False
		elif palabra[cletra] == 'r':
			if cletra < len(palabra)-1:
				if palabra[cletra+1] == 'r':
					fonema = 'rr'
					eletra = False
					cletra += 1
				else:
					fonema = 'r'
					eletra = False
			else:
				fonema = 'r'
				eletra = False
		if eletra == True:
			fonema = palabra[cletra]
		fonetica = fonetica + fonema
		fonetica = fonetica + ' '
		cletra += 1
	fonetica = fonetica.rstrip()
#	print palabra+fonetica
#-----------------------------------------------------

	U = palabra.decode('utf8')
	UM = U.upper()
	palabra = UM.encode('utf8')

	fw.write(palabra+fonetica+'\n')
#	fw.write(palabra+'\n')
	contador += 1
print 'Escritas '+str(contador)+' lineas en salida.dict'
fr.close()
fw.close()
