#!/usr/bin/env python
# -*- codding: utf-8 -*-

import sys
import os
import time

print '\n###########################################################'
print '             Script de grabacion para Julius'
print '###########################################################\n\n'
print 'Se va a proceder a la grabacion de archivos  para procesarlos con htk'
print 'y crear asi  un  modelo de lenguaje para julius. Durante este proceso'
print 'se  comprobara que las palabras en el archivo de lineas existen en el'
print 'diccionario voxforge_lexicon prevenir errores posteriores, tenga esto'
print 'en cuenta si modifica las frases o escribe nuevas.\n\n'

i_frases = 'frases.txt'
i_lexicon = '../con/lexicon/voxforge_lexicon'
s_dispositivo = ''

def comprueba_lexicon():
    global i_frases
    global i_lexicon
    estado_general = True
    a_frases = open(i_frases, 'r')
    #comprobar que las palabras existen en el lexicon
    print 'COMPROBANDO LEXICON... Espere'

###############################################################
    for linea in a_frases.xreadlines():
        linea = linea[:len(linea)-1]
        letra = ''
        cletra = 0
        palabras = linea.split(' ')
        for palabra in palabras:
            cletra = 0

            U = palabra.decode('utf8')
            UM = U.upper()
            ppalabra = UM.encode('utf8')

            encontrada = False
            a_lexicon = open(i_lexicon,'r')
            for lexicon_linea in a_lexicon.xreadlines():
                cletra = 0
                lexicon_palabra = ''
                while (cletra < len(lexicon_linea)) and lexicon_linea != ' ':
                    if lexicon_linea[cletra] == ' ':
                        break
                    lexicon_palabra = lexicon_palabra + lexicon_linea[cletra]
                    cletra += 1
                if ppalabra == lexicon_palabra:
                    encontrada = True
            a_lexicon.close()
            if encontrada == False:
                print 'La palabra '+palabra+' ['+ppalabra+'] no existen en voxforge_lexicon'
                estado_general = False

    a_frases.close()
    if estado_general == False:
        print 'Compruebe el archivo voxforge_lexicon o elimine la/s palabra/s que no existe/n de su archivo de frases'
        sys.exit(1)

def grabacion(numero):
    global s_dispositivo
    print '\nGrabando muestra'+str(numero)+'.wav en la carpeta train/wav'
    os.system('arecord -D plughw:'+s_dispositivo+' -c 1 -f S16_LE -r 16000 --vumeter=mono train/wav/muestra'+str(numero)+'.wav')
    print '\n\n'

def m_grabacion():
    global i_frases

    if os.path.isfile(i_frases):
        a_frases = open(i_frases,'r')
    else:
        print 'ERROR: El archivo de frases '+i_frases+' no existe'
        sys.exit(1)

    comprueba_lexicon()

    if not os.path.isdir('train'):
        os.system('mkdir train')
        os.system('mkdir train/wav')

    os.system('clear')
    print 'Seguidamente se van a mostrar frases que usted debera leer de forma normal,'
    print 'escuchara un bip que le indicara que la grabacion ha comenzado.'
    print 'Cuando haya terminado la grabacion presione Ctrl+c para continuar con la siguiente.\n'
    print 'IMPORTANTE: RECUERDE DEJAR UNA PAUSA'
    print '            DE MEDIO SEGUNDO APROXIMADAMENTE'
    print '            AL INICIO Y AL FINAL DE CADA GRABACION.\n'

    null = raw_input('Presione intro cuando este preparado')
    numero = 0
    while os.path.isfile('train/wav/muestra'+str(numero)+'.wav'):
        numero += 1
    for linea in a_frases.xreadlines():
        os.system('clear')
        print 'Frase a leer: '+linea
        null = raw_input('### Presione Intro cuando este preparado ###')
        os.system('aplay -q beep.wav')
        time.sleep(0.2)
        grabacion(numero)
        a_cadena = open('train/wav/muestra'+str(numero)+'.txt','w')
        a_cadena.write(linea)
        a_cadena.close()
        numero += 1
    print '\n###### Grabacion finalizada ######\n'
    a_frases.close()

def menu():
    global s_dispositivo
    print '#################################################'
    print '                      Menu'
    print '#################################################\n'
    print '    1 - probar el microfono'
    print '    2 - grabar frases'
    print '    3 - seleccion dispositivo de captura'
    if s_dispositivo != '':
        print '      - dispositivo de captura seleccionado -'
    print '    0 - salir\n'
    seleccion = raw_input('entrenador: ')
    if seleccion == '1':
        if s_dispositivo != '':
            print 'Se van a grabar 5 segundos utilizando el dispositivo seleccionado'
            print 'seguidamente se reproducira.'
            null = raw_input('Presione Intro cuando este preparado')
            os.system('arecord -D plughw:'+s_dispositivo+' --duration=5 -c 1 -f S16_LE -r 16000 --vumeter=mono rectest.wav')
            print '\nReproduccion...'
            os.system('aplay rectest.wav')
            os.system('rm rectest.wav')
        else:
            print 'ERROR: Seleccione primero el dispositivo de captura'
        menu()
    elif seleccion == '2':
        if s_dispositivo != '':
            m_grabacion()
        else:
            print 'ERROR. Seleccione primero el dispositivo de captura'
            menu()
    elif seleccion == '3':
        print 'Dispositivo de entrada:'
        os.system('arecord -l')
        s_dispositivo = raw_input('Seleccione el numero de tarjeta: ')
        menu()
    elif seleccion == '0':
        sys.exit(0)
    else:
        sys.exit(1)

def main():
    global i_frases
    global i_lexicon
    if len(sys.argv) > 1:
        i_frases = sys.argv[1]
    if not os.path.isfile(i_lexicon):
        print 'ERROR: El archivo voxforge_lexicon no existe en la ruta marcelino-dev/escucha/con/lexicon/\n'
        sys.exit(1)
    menu()
#comprobacion de archivo de frases o frases predefinidas
#   una frase en cada linea
#busqueda en el lexicon de las palabras de cada frases
#errores
#menu
# 1 - probar el microfono
# 2 - grabar frases
#grabacion de archivos
#comprobacion de grabaciones en carpeta train de entrenador
#solicitud de continuar si hay mas lineas a grabar

if __name__ == '__main__':
    main()
