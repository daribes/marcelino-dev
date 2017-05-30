#!/usr/bin/env python
import os
import sys
import pyjulius3
import Queue as queue
import time

# aqui tts solamente
def habla(frase):
#    print 'MIC OFF'
    os.system('amixer -D pulse set Capture volume 100% toggle > /dev/null 2>&1')
    os.system('echo \"'+frase+'\" | festival --tts --language castillian')
    os.system('amixer -D pulse set Capture volume 100% toggle > /dev/null 2>&1')
#    print 'MIN ON'

# vamos a intentar hacer algo inteligente
def piensa(resultado):
    frase = ''
    for x in range(0,len(resultado.words)):
        frase = frase+' '+resultado.words[x].word
    frase = frase.strip()

    if frase == 'MARCELINO':
        habla('que tal?')
    elif frase == 'HOLA MARCELINO':
        if 6 <= int(time.strftime("%H")) and int(time.strftime("%H")) < 12:
            habla('buenos dias')
        elif 12 <= int(time.strftime("%H")) and int(time.strftime("%H")) < 21:
            habla('buenas tardes')
        elif 21 <= int(time.strftime("%H")) and int(time.strftime("%H")) < 24:
            habla('buenas noches')
        elif 0 <= int(time.strftime("%H")) and int(time.strftime("%H")) < 6:
            habla('buenas noches')
    else:
        habla(frase)


def main():
    # Inicializacion y conexion con el servidor
    client = pyjulius3.Client('localhost', 10500)
    try:
        client.connect()
    except pyjulius3.ConnectionError:
        print 'Inicie el servidor julius primero...'
        sys.exit(1)

    # aqui escuchamos lo que se dice
    client.start()
    print '<<< A sus ordenes >>>'
    try:
        while 1:
            time.sleep(0.001)

            try:
                result = client.results.get(False)
                if len(result) > 0:
                    piensa(result)

            except queue.Empty:
                continue
#               print repr(result)

    except KeyboardInterrupt:
        print 'Saliendo...'
        client.disconnect()

# DISCRIMINACION DE HABLANTES
# INTELIGENCIA
main()
