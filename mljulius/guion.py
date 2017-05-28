#!/usr/bin/env python
# -*- codding: utf-8 -*-

#Guion para la creacion automatizada de un modelo de lenguaje

import sys
import os
from subprocess import Popen, PIPE

def check_execs(*progs):
    """Check if the programs are installed, if not exit and report."""
    for prog in progs:
        try:
            Popen([prog, '--help'], stdout=PIPE, stderr=PIPE)
        except OSError:
            msg = 'El programa {0} es necesario para poder ejecutar este script'.format(prog)
            sys.exit(msg)
    return

def main():
    try:
        if sys.argv[1] != '':
            archivo = sys.argv[1]
    except:
        print 'ERROR: Debe indicar el nombre de un archivo: guion.py [archivo]'
        print '  Si es la primera vez que ejecuta este script (o no se acuerda de como) '
        print '  eche un vistazo al archivo README, como pista, debe tener creados los '
        print '  archivos .voca y .grammar con el mismo nombre y pasar este nombre como '
        print '  parametro de este script.'
        sys.exit(0)

#comprobar que existe el set HTK
#comprobar que existen todos los archivos bin y si no intentar descargarlos
#tener disponible bin/mkdfa.jl en la carpeta con/bin
#tener disponible el archivo prompts.txt
#tener disponible bin/pyvoca.py
#tener disponible bin/prompts2wlist.jl
#tener disponible bin/maM.py
#tener disponible bin/mktrihed.jl
#tener disponible bin/fixfulllist.jl
#tener disponible el archivo glogal.ded
#tener disponible el archivo lexicon/voxforge_lexicon
#tener disponible el set HTK en la carpeta htk
#tener disponibles las grabaciones en la carpeta train/wav
#tener disponible el archivo bin/prompts2mlf.jl
#tener disponible el archivo mkfonemas0.led
#tener disponible el archivo mkfonemas1.led
#tener disponible el archivo codetrain.scp
#tener disponible el archivo wav_config
#tener disponible el archivo proto
#tener disponible el archivo config
#tener disponible el archivo train.scp
#tener disponible el archivo sil.hed
#tener disponible el archivo mktri.led
#tener disponible el archivo maketriphones.ded
#tener disponible el archivo tree.hed
#tener disponible el archivo sample.jconf

#crear sample.grammar (archivo de definicion de gramatica)
#    fw = open('con/sample.grammar','w')
#    fw.write('S: NS_B SALUDO NS_E\n')
#    fw.write('S: NS_B SALUDO SALUDO NS_E\n')
#    fw.write('S: NS_B SALUDO SALUDO SALUDO NS_E\n')
#    fw.close()
#crear sample.voca (archivo de vocabulario)
#    os.system('con/bin/pyvoca.py '+sys.argv[1])
#    os.system('con/bin/maM.py '+sys.argv[1]+'_voca')
#    os.system('mv '+sys.argv[1]+'_voca con/')
#    os.system('mv salida.dict con/')
#    fo = open('con/salida.dict','r')
#    fw = open('con/sample.voca','w')
#    fw.write('% NS_B\n')
#    fw.write('<s> sil\n')
#    fw.write('\n')
#    fw.write('% NS_E\n')
#    fw.write('</s> sil\n')
#    fw.write('\n')
#    fw.write('% SALUDO\n')
#    for linea in fo.xreadlines():
#        fw.write(linea)
#    fw.close()
#    fo.close()

#ejecutar julia bin/mkdfa.jl sample (creacion de .dfa y .dict)
    fl = open('guion.log','w')
    ruta = os.getcwd()+'/'+archivo
    os.chdir('con')
    try:
        os.system('julia bin/mkdfa.jl '+ruta)
        fl.write('X: julia bin/mkdfa.jl '+ruta+'\n')
    except:
        print 'ERROR1: No se puede ejecutar bin/mkdfa.jl'
        fl.write('ERROR1: No se puede ejecutar bin/mkdfa.jl\n')
        sys.exit(0)
    if os.path.isfile(ruta+'.dict'):
        os.system('cp '+ruta+'.dict .')
        fl.write('X: cp '+ruta+'.dict .\n')
    else:
        print 'ERROR2: No se ha podido copiar '+ruta+'.dict'
        fl.write('ERROR2: No se ha podido copiar '+ruta+'.dict\n')
        sys.exit(0)
    if os.path.isfile(ruta+'.dfa'):
        os.system('cp '+ruta+'.dfa .')
        fl.write('X: cp '+ruta+'.dfa .\n')
    else:
        print 'ERROR3: No se ha podido copiar '+ruta+'.dfa'
        fl.write('ERROR3: No se ha podido copiar '+ruta+'.dfa\n')
        sys.exit(0)
#ejecutar julia bin/prompts2wlist.jl prompts.txt wlist
    try:
        os.system('julia bin/prompts2wlist.jl prompts.txt wlist')
        fl.write('X: julia bin/prompts2wlist.jl prompts.txt wlist\n')
    except:
        print 'ERROR4: No se ha podido ejecutar bin/prompts2wlist.jl'
        fl.write('ERROR4: No se ha podido ejecutar bin/prompts2wlist.jl\n')
        sys.exit(0)
    if not os.path.isfile('wlist'):
        print 'ERROR5: No se encuenta el archivo wlist'
        fl.write('ERROR5: No se encuenta el archivo wlist\n')
        sys.exit(0)
#ejecutar htk/HTKTools/HDMan -A -D -T 1 -m -w wlist -n monophones1 -i -l dlog dict lexicon/voxforge_lexicon
    try:
        os.system('htk/HTKTools/HDMan -A -D -T 1 -m -w wlist -n monophones1 -i -l dlog dict lexicon/voxforge_lexicon')
        fl.write('X: htk/HTKTools/HDMan -A -D -T 1 -m -w wlist -n monophones1 -i -l dlog dict lexicon/voxforge_lexicon\n')
    except:
        print 'ERROR6: No se ha podido ejecutar htk/HTKTools/HDMan'
        fl.write('ERROR6: No se ha podido ejecutar htk/HTKTools/HDMan\n')
        sys.exit(0)
    if not os.path.isfile('monophones1'):
        print 'ERROR6b: No se encuentra el archivo monophones1'
        fl.write('ERROR6b: No se encuentra el archivo monophones1\n')
        sys.exit(0)
#crear copia de monophones1 en monophones0 sin la linea sp
    fr = open('monophones1','r')
    fw = open('monophones0','w')
    for linea in fr.xreadlines():
        linea = linea.strip()
        if linea != 'sp':
            fw.write(linea+'\n')
    fw.write('\n')
    fw.close()
    fr.close()
    fl.write('X: Creando monophones0\n')
    if not os.path.isfile('monophones0'):
        print 'ERROR7: No existe el archivo monophones0'
        fl.write('ERROR7: No existe el archivo monophones0\n')
        sys.exit(0)
#ejecutar julia bin/prompts2mlf.jl prompts.txt palabras.mlf
    try:
        os.system('julia bin/prompts2mlf.jl prompts.txt palabras.mlf')
        fl.write('X: julia bin/prompts2mlf.jl prompts.txt palabras.mlf\n')
    except:
        print 'ERROR8: no se ha podido ejecutar bin/prompts2mlf.jl'
        fl.write('ERROR8: no se ha podido ejecutar bin/prompts2mlf.jl\n')
        sys.exit(0)
    if not os.path.isfile('palabras.mlf'):
        print 'ERROR9: No se encuentra el archivo palabras.mlf'
        fl.write('ERROR9: No se encuentra el archivo palabras.mlf\n')
        sys.exit(0)
#ejecutar htk/HTKTools/HLEd -A -D -T 1 -l '*' -d dict -i fonemas0.mlf mkfonemas0.led palabras.mlf
    try:
        os.system('htk/HTKTools/HLEd -A -D -T 1 -l \'*\' -d dict -i fonemas0.mlf mkfonemas0.led palabras.mlf')
        fl.write('X: htk/HTKTools/HLEd -A -D -T 1 -l \'*\' -d dict -i fonemas0.mlf mkfonemas0.led palabras.mlf\n')
    except:
        print 'ERROR10: No se ha podido ejecutar htk/HTKTools/HLEd'
        fl.write('ERROR10: No se ha podido ejecutar htk/HTKTools/HLEd\n')
        sys.exit(0)
    if not os.path.isfile('fonemas0.mlf'):
        print 'ERROR11: No se enuentra el archivo fonemas0.mlf'
        fl.write('ERROR11: No se enuentra el archivo fonemas0.mlf\n')
        sys.exit(0)
#ejecutar htk/HTKTools/HLEd -A -D -T 1 -l '*' -d dict -i fonemas1.mlf mkfonemas1.led palabras.mlf
    try:
        os.system('htk/HTKTools/HLEd -A -D -T 1 -l \'*\' -d dict -i fonemas1.mlf mkfonemas1.led palabras.mlf')
        fl.write('X: htk/HTKTools/HLEd -A -D -T 1 -l \'*\' -d dict -i fonemas1.mlf mkfonemas1.led palabras.mlf\n')
    except:
        print 'ERROR12: No se ha podido ejecutar htk/HTKTools/HLEd'
        fl.write('ERROR12: No se ha podido ejecutar htk/HTKTools/HLEd\n')
        sys.exit(0)
    if not os.path.isfile('fonemas1.mlf'):
        print 'ERROR13: No se encuentra el archivo fonemas1.mlf'
        fl.write('ERROR13: No se encuentra el archivo fonemas1.mlf\n')
        sys.exit(0)
#crear la carepta train/mfcc
    if not os.path.isdir('train/mfcc'):
        try:
            os.system('mkdir train/mfcc')
            fl.write('X: mkdir train/mfcc\n')
        except:
            print 'ERROR14: No se ha podido crear la carpeta train/mfcc'
            fl.write('ERROR14: No se ha podido crear la carpeta train/mfcc\n')
            sys.exit(0)
    if not os.path.isdir('train/mfcc'):
        print 'ERROR15: No se encuentra la carpeta train/mfcc'
        fl.write('ERROR15: No se encuentra la carpeta train/mfcc\n')
        sys.exit(0)
#ejecutar htk/HTKTools/HCopy -A -D -T 1 -C wav_config -S codetrain.scp
    try:
        os.system('htk/HTKTools/HCopy -A -D -T 1 -C wav_config -S codetrain.scp')
        fl.write('X: htk/HTKTools/HCopy -A -D -T 1 -C wav_config -S codetrain.scp\n')
    except:
        print 'ERROR16: No se ha podido ejecutar htk/HTKTools/HCopy'
        fl.write('ERROR16: No se ha podido ejecutar htk/HTKTools/HCopy\n')
        sys.exit(0)
    if not os.path.isfile('codetrain.scp'):
        print 'ERROR17: No se encuentra el archivo codetrain.scp'
        fl.write('ERROR17: No se encuentra el archivo codetrain.scp\n')
        sys.exit(0)
#crear la carpeta hmm0
    if not os.path.isdir('hmm0'):
        try:
            os.system('mkdir hmm0')
            fl.write('X: mkdir hmm0\n')
        except:
            print 'ERROR18: No se ha podido crear la carpeta hmm0'
            fl.write('ERROR18: No se ha podido crear la carpeta hmm0\n')
            sys.exit(0)
#ejecutar htk/HTKTools/HCompV -A -D -T 1 -C config -f 0.01 -m -S train.scp -M hmm0 proto
    try:
        os.system('htk/HTKTools/HCompV -A -D -T 1 -C config -f 0.01 -m -S train.scp -M hmm0 proto')
        fl.write('X: htk/HTKTools/HCompV -A -D -T 1 -C config -f 0.01 -m -S train.scp -M hmm0 proto\n')
    except:
        print 'ERROR19: No se ha podido ejecutar htk/HTKTools/HCompV'
        fl.write('ERROR19: No se ha podido ejecutar htk/HTKTools/HCompV\n')
        sys.exit(0)
#copiar el archivo monophones0 a la carpeta hmm0 como hmmdefs
#poner el fonema entre comillas dobles
#agregar '~h ' antes del fonema
#copiar desde la linea 5 en adelante del archivo hmm0/proto y pegarlo despues de cada fonema
    fr = open('monophones0','r')
    fw = open('hmm0/hmmdefs','w')
    for linea in fr.xreadlines():
        linea = linea.strip()
        if linea != '':
            linea1 = '~h \"'+linea+'\"'
            fw.write(linea1+'\n')
            fr1 = open('hmm0/proto','r')
            contador = 0
            for linea1 in fr1.xreadlines():
                if contador >= 4:
                    fw.write(linea1)
                contador += 1
            fr1.close()
    fw.close()
    fr.close()
    fl.write('X: Creando hmm0/hmmdefs\n')
    if not os.path.isfile('hmm0/hmmdefs'):
        print 'ERROR20: No se encuentra el archivo hmm0/hmmdefs'
        fl.write('ERROR20: No se encuentra el archivo hmm0/hmmdefs\n')
        sys.exit(0)
#copia hmm0/vFloors a hmm0/macros
#copiar las 3 primeras lineas de proto y agregarlas a la parte superior del archivo de macros
    fr = open('hmm0/proto','r')
    fr1 = open('hmm0/vFloors','r')
    fw = open('hmm0/macros','w')
    contador = 0
    for linea in fr.xreadlines():
        if contador < 3:
            fw.write(linea)
            contador += 1
        else:
            break
    for linea in fr1.xreadlines():
        fw.write(linea)
    fw.close()
    fr1.close()
    fr.close()
    fl.write('X: Creando hmm0/macros\n')
    if not os.path.isfile('hmm0/macros'):
        print 'ERROR21: No se encuentra el archivo hmm0/macros'
        fl.write('ERROR21: No se encuentra el archivo hmm0/macros\n')
        sys.exit(0)
#crear 9 carpetas hmm1-9
    for x in range(1,10):
        fl.write('X: Creando hmm'+str(x)+'\n')
        if not os.path.isdir('hmm'+str(x)):
            try:
                os.system('mkdir hmm'+str(x))
            except:
                print 'ERROR22: No se han podido crear la carpeta hmm'+str(x)
                fl.write('ERROR22: No se han podido crear la carpeta hmm'+str(x)+'\n')
                sys.exit(0)
#ejecutar htk/HTKTools/HERest -A -D -T 1 -C config -I fonemas0.mlf -t 250.0 150.0 1000.0 -S train.scp -H hmm0/macros -H hmm0/hmmdefs -M hmm1 monophones0
    try:
        os.system('htk/HTKTools/HERest -A -D -T 1 -C config -I fonemas0.mlf -t 250.0 150.0 1000.0 -S train.scp -H hmm0/macros -H hmm0/hmmdefs -M hmm1 monophones0')
        fl.write('X: htk/HTKTools/HERest -A -D -T 1 -C config -I fonemas0.mlf -t 250.0 150.0 1000.0 -S train.scp -H hmm0/macros -H hmm0/hmmdefs -M hmm1 monophones0\n')
    except:
        print 'ERROR23: No se ha podido ejecutar htk/HTKTools/HERest'
        fl.write('ERROR23: No se ha podido ejecutar htk/HTKTools/HERest\n')
        sys.exit(0)
#ejecutar htk/HTKTools/HERest -A -D -T 1 -C config -I fonemas0.mlf -t 250.0 150.0 1000.0 -S train.scp -H hmm1/macros -H hmm1/hmmdefs -M hmm2 monophones0
    try:
        os.system('htk/HTKTools/HERest -A -D -T 1 -C config -I fonemas0.mlf -t 250.0 150.0 1000.0 -S train.scp -H hmm1/macros -H hmm1/hmmdefs -M hmm2 monophones0')
        fl.write('X: htk/HTKTools/HERest -A -D -T 1 -C config -I fonemas0.mlf -t 250.0 150.0 1000.0 -S train.scp -H hmm1/macros -H hmm1/hmmdefs -M hmm2 monophones0\n')
    except:
        print 'ERROR24: No se ha podido ejecutar htk/HTKTools/HERest'
        fl.write('ERROR24: No se ha podido ejecutar htk/HTKTools/HERest\n')
        sys.exit(0)
#ejecutar htk/HTKTools/HERest -A -D -T 1 -C config -I fonemas0.mlf -t 250.0 150.0 1000.0 -S train.scp -H hmm2/macros -H hmm2/hmmdefs -M hmm3 monophones0
    try:
        os.system('htk/HTKTools/HERest -A -D -T 1 -C config -I fonemas0.mlf -t 250.0 150.0 1000.0 -S train.scp -H hmm2/macros -H hmm2/hmmdefs -M hmm3 monophones0')
        fl.write('X: htk/HTKTools/HERest -A -D -T 1 -C config -I fonemas0.mlf -t 250.0 150.0 1000.0 -S train.scp -H hmm2/macros -H hmm2/hmmdefs -M hmm3 monophones0\n')
    except:
        print 'ERROR25: No se ha podido ejecutar htk/HTKTools/HERest'
        fl.write('ERROR25: No se ha podido ejecutar htk/HTKTools/HERest\n')
        sys.exit(0)
#copiar el contenido de hmm3 a hmm4
    try:
        os.system('cp -r hmm3/* hmm4/')
        fl.write('X: Copiando contenido de hmm3 a hmm4\n')
    except:
        print 'ERROR26: No se ha podido copiar el contenido de hmm3 a hmm4'
        fl.write('ERROR26: No se ha podido copiar el contenido de hmm3 a hmm4\n')
        sys.exit(0)
#copiar el modelo sil dentro de hmm4/hmmdefs
#eliminar estado 2 y estado 4
#cambiar <NUMSTATES> a 3
#cambiar <STATE> a 2
#cambiar <TRANSP> a 3
#cambiar matriz en <TRANSP> a 3 por 3 matriz
# 0.0 1.0 0.0
# 0.0 0.9 0.1
# 0.0 0.0 0.0
    try:
        os.system('rm hmm4/hmmdefs')
        fl.write('X: Elinando hmm4/hmmdefs\n')
    except:
        print 'ERROR26b: No se ha podido eliminar hmm4/hmmdefs'
        fl.write('ERROR26b: No se ha podido eliminar hmm4/hmmdefs\n')
        sys.exit(0)
    fl.write('X: Creando hmm4/hmmdefs\n')
    fr = open('hmm3/hmmdefs','r')
    fw = open('hmm4/hmmdefs','w')
    for linea in fr.xreadlines():
        fw.write(linea)
    fr.close()
    fw.write('~h \"sp\"\n')
    fw.write('<BEGINHMM>\n')
    fw.write('<NUMSTATES> 3\n')
    fr = open('hmm3/hmmdefs')
    estado1 = False
    etiqueta = ''
    etiqueta1 = ''
    for linea in fr.xreadlines():
        if len(linea) >= 9:
            etiqueta = linea[0]+linea[1]+linea[2]+linea[3]+linea[4]+linea[5]+linea[6]+linea[7]+linea[8]
            etiqueta2 = linea[0]+linea[1]+linea[2]+linea[3]+linea[4]+linea[5]+linea[6]+linea[7]
        if estado1 == True:
            fw.write(linea)
            if etiqueta2 == '<GCONST>':
                break
        if etiqueta == '<STATE> 3':
            fw.write('<STATE> 2\n')
            estado1 = True
    fw.write('<TRANSP> 3\n')
    fw.write(' 0.0 1.0 0.0\n')
    fw.write(' 0.0 0.9 0.1\n')
    fw.write(' 0.0 0.0 0.0\n')
    fw.write('<ENDHMM>\n')
    fr.close()
    fw.close()
    if not os.path.isfile('hmm4/hmmdefs'):
        print 'ERROR27: No se encuentra el archivo hmm4/hmmdefs'
        fl.write('ERROR27: No se encuentra el archivo hmm4/hmmdefs\n')
        sys.exit(0)
#ejecutar htk/HTKTools/HHEd -A -D -T 1 -H hmm4/macros -H hmm4/hmmdefs -M hmm5 sil.hed monophones1
    try:
        os.system('htk/HTKTools/HHEd -A -D -T 1 -H hmm4/macros -H hmm4/hmmdefs -M hmm5 sil.hed monophones1')
        fl.write('X: htk/HTKTools/HHEd -A -D -T 1 -H hmm4/macros -H hmm4/hmmdefs -M hmm5 sil.hed monophones1\n')
    except:
        print 'ERROR28: No se ha podido ejecutar htk/HTKTools/HHEd'
        fl.write('ERROR28: No se ha podido ejecutar htk/HTKTools/HHEd\n')
        sys.exit(0)
#ejecutar htk/HTKTools/HERest -A -D -T 1 -C config  -I fonemas1.mlf -t 250.0 150.0 3000.0 -S train.scp -H hmm5/macros -H  hmm5/hmmdefs -M hmm6 monophones1
    try:
        os.system('htk/HTKTools/HERest -A -D -T 1 -C config  -I fonemas1.mlf -t 250.0 150.0 3000.0 -S train.scp -H hmm5/macros -H  hmm5/hmmdefs -M hmm6 monophones1')
        fl.write('X: htk/HTKTools/HERest -A -D -T 1 -C config  -I fonemas1.mlf -t 250.0 150.0 3000.0 -S train.scp -H hmm5/macros -H  hmm5/hmmdefs -M hmm6 monophones1\n')
    except:
        print 'ERROR29: No se ha podido ejecutar htk/HTKTools/HERest'
        fl.write('ERROR29: No se ha podido ejecutar htk/HTKTools/HERest\n')
        sys.exit(0)
#ejecutar htk/HTKTools/HERest -A -D -T 1 -C config  -I fonemas1.mlf -t 250.0 150.0 3000.0 -S train.scp -H hmm6/macros -H hmm6/hmmdefs -M hmm7 monophones1
    try:
        os.system('htk/HTKTools/HERest -A -D -T 1 -C config  -I fonemas1.mlf -t 250.0 150.0 3000.0 -S train.scp -H hmm6/macros -H hmm6/hmmdefs -M hmm7 monophones1')
        fl.write('X: htk/HTKTools/HERest -A -D -T 1 -C config  -I fonemas1.mlf -t 250.0 150.0 3000.0 -S train.scp -H hmm6/macros -H hmm6/hmmdefs -M hmm7 monophones1\n')
    except:
        print 'ERROR30: No se ha podido ejecutar htk/HTKTools/HERest'
        fl.write('ERROR30: No se ha podido ejecutar htk/HTKTools/HERest\n')
        sys.exit(0)
#ejecutar htk/HTKTools/HVite -A -D -T 1 -l '*' -o SWT -b SENT-END -C config -H hmm7/macros -H hmm7/hmmdefs -i aligned.mlf -m -t 250.0 150.0 1000.0 -y lab -a -I palabras.mlf -S train.scp dict monophones1> HVite_log
    try:
        os.system('htk/HTKTools/HVite -A -D -T 1 -l \'*\' -o SWT -b SENT-END -C config -H hmm7/macros -H hmm7/hmmdefs -i aligned.mlf -m -t 250.0 150.0 1000.0 -y lab -a -I palabras.mlf -S train.scp dict monophones1> HVite_log')
        fl.write('X: htk/HTKTools/HVite -A -D -T 1 -l \'*\' -o SWT -b SENT-END -C config -H hmm7/macros -H hmm7/hmmdefs -i aligned.mlf -m -t 250.0 150.0 1000.0 -y lab -a -I palabras.mlf -S train.scp dict monophones1> HVite_log\n')
    except:
        print 'ERROR31: No se ha podido ejecutar htk/HTKTools/HVite'
        fl.write('ERROR31: No se ha podido ejecutar htk/HTKTools/HVite\n')
        sys.exit(0)
#[posibles erroes en hvite_log]
#ejecutar htk/HTKTools/HERest -A -D -T 1 -C config -I aligned.mlf -t 250.0 150.0 3000.0 -S train.scp -H hmm7/macros -H hmm7/hmmdefs -M hmm8 monophones1
    try:
        os.system('htk/HTKTools/HERest -A -D -T 1 -C config -I aligned.mlf -t 250.0 150.0 3000.0 -S train.scp -H hmm7/macros -H hmm7/hmmdefs -M hmm8 monophones1')
        fl.write('X: htk/HTKTools/HERest -A -D -T 1 -C config -I aligned.mlf -t 250.0 150.0 3000.0 -S train.scp -H hmm7/macros -H hmm7/hmmdefs -M hmm8 monophones1\n')
    except:
        print 'ERROR32: No se ha podido ejecutar htk/HTKTools/HERest'
        fl.write('ERROR32: No se ha podido ejecutar htk/HTKTools/HERest\n')
        sys.exit(0)
#ejecutar htk/HTKTools/HERest -A -D -T 1 -C config -I aligned.mlf -t 250.0 150.0 3000.0 -S train.scp -H hmm8/macros -H hmm8/hmmdefs -M hmm9 monophones1
    try:
        os.system('htk/HTKTools/HERest -A -D -T 1 -C config -I aligned.mlf -t 250.0 150.0 3000.0 -S train.scp -H hmm8/macros -H hmm8/hmmdefs -M hmm9 monophones1')
        fl.write('X: htk/HTKTools/HERest -A -D -T 1 -C config -I aligned.mlf -t 250.0 150.0 3000.0 -S train.scp -H hmm8/macros -H hmm8/hmmdefs -M hmm9 monophones1\n')
    except:
        print 'ERROR32: No se ha podido ejecutar htk/HTKTools/HERest'
        fl.write('ERROR32: No se ha podido ejecutar htk/HTKTools/HERest\n')
        sys.exit(0)
#ejecutar htk/HTKTools/HLEd -A -D -T 1 -n triphones1 -l '*' -i wintri.mlf mktri.led aligned.mlf
    try:
        os.system('htk/HTKTools/HLEd -A -D -T 1 -n triphones1 -l \'*\' -i wintri.mlf mktri.led aligned.mlf')
        fl.write('X: htk/HTKTools/HLEd -A -D -T 1 -n triphones1 -l \'*\' -i wintri.mlf mktri.led aligned.mlf\n')
    except:
        print 'ERROR33: No se ha podido ejecutar htk/HTKTools/HLEd'
        fl.write('ERROR33: No se ha podido ejecutar htk/HTKTools/HLEd\n')
        sys.exit(0)
#ejecutar julia bin/mktrihed.jl monophones1 triphones1 mktri.hed
    try:
        os.system('julia bin/mktrihed.jl monophones1 triphones1 mktri.hed')
        fl.write('X: julia bin/mktrihed.jl monophones1 triphones1 mktri.hed\n')
    except:
        print 'ERROR34: No se ha podido ejecutar bin/mktrihed.jl'
        fl.write('ERROR34: No se ha podido ejecutar bin/mktrihed.jl\n')
        sys.exit(0)
#crear carpetas hmm10-12
    for x in range(10,14):
        fl.write('X: Creando hmm'+str(x)+'\n')
        if not os.path.isdir('hmm'+str(x)):
            try:
                os.system('mkdir hmm'+str(x))
            except:
                print 'ERROR35: No se ha podido crear la carpeta hmm'+str(x)
                fl.write('ERROR35: No se ha podido crear la carpeta hmm'+str(x)+'\n')
                sys.exit(0)
#ejecutar htk/HTKTools/HHEd -A -D -T 1 -H hmm9/macros -H hmm9/hmmdefs -M hmm10 mktri.hed monophones1
    try:
        os.system('htk/HTKTools/HHEd -A -D -T 1 -H hmm9/macros -H hmm9/hmmdefs -M hmm10 mktri.hed monophones1')
        fl.write('X: htk/HTKTools/HHEd -A -D -T 1 -H hmm9/macros -H hmm9/hmmdefs -M hmm10 mktri.hed monophones1\n')
    except:
        print 'ERROR36: No se ha podido ejecutar htk/HTKTools/HHEd'
        fl.write('ERROR36: No se ha podido ejecutar htk/HTKTools/HHEd\n')
        sys.exit(0)
#ejecutar htk/HTKTools/HERest -A -D -T 1 -C config -I wintri.mlf -t 250.0 150.0 3000.0 -S train.scp -H hmm10/macros -H hmm10/hmmdefs -M hmm11 triphones1
    try:
        os.system('htk/HTKTools/HERest -A -D -T 1 -C config -I wintri.mlf -t 250.0 150.0 3000.0 -S train.scp -H hmm10/macros -H hmm10/hmmdefs -M hmm11 triphones1')
        fl.write('X: htk/HTKTools/HERest -A -D -T 1 -C config -I wintri.mlf -t 250.0 150.0 3000.0 -S train.scp -H hmm10/macros -H hmm10/hmmdefs -M hmm11 triphones1\n')
    except:
        print 'ERROR37: No se ha podido ejecutar htk/HTKTools/HERest'
        fl.write('ERROR37: No se ha podido ejecutar htk/HTKTools/HERest\n')
        sys.exit(0)
#ejecutar htk/HTKTools/HERest -A -D -T 1 -C config -I wintri.mlf -t 250.0 150.0 3000.0 -s stats -S train.scp -H hmm11/macros -H hmm11/hmmdefs -M hmm12 triphones1
    try:
        os.system('htk/HTKTools/HERest -A -D -T 1 -C config -I wintri.mlf -t 250.0 150.0 3000.0 -s stats -S train.scp -H hmm11/macros -H hmm11/hmmdefs -M hmm12 triphones1')
        fl.write('X: htk/HTKTools/HERest -A -D -T 1 -C config -I wintri.mlf -t 250.0 150.0 3000.0 -s stats -S train.scp -H hmm11/macros -H hmm11/hmmdefs -M hmm12 triphones1\n')
    except:
        print 'ERROR38: No se ha podido ejecutar htk/HTKTools/HERest'
        fl.write('ERROR38: No se ha podido ejecutar htk/HTKTools/HERest\n')
        sys.exit(0)
#ejecutar htk/HTKTools/HDMan -A -D -T 1 -b sp -n fulllist0 -g maketriphones.ded -l flog dict-tri lexicon/voxforge_lexicon
    try:
        os.system('htk/HTKTools/HDMan -A -D -T 1 -b sp -n fulllist0 -g maketriphones.ded -l flog dict-tri lexicon/voxforge_lexicon')
        fl.write('X: htk/HTKTools/HDMan -A -D -T 1 -b sp -n fulllist0 -g maketriphones.ded -l flog dict-tri lexicon/voxforge_lexicon\n')
    except:
        print 'ERROR39: No se ha podido ejecutar htk/HTKTools/HDMan'
        fl.write('ERROR39: No se ha podido ejecutar htk/HTKTools/HDMan\n')
        sys.exit(0)
#ejecutar julia bin/fixfulllist.jl fulllist0 monophones0 fulllist
    try:
        os.system('julia bin/fixfulllist.jl fulllist0 monophones0 fulllist')
        fl.write('X: julia bin/fixfulllist.jl fulllist0 monophones0 fulllist\n')
    except:
        print 'ERROR40: No se ha podido ejecutar bin/fixfulllist.jl'
        fl.write('ERROR40: No se ha podido ejecutar bin/fixfulllist.jl\n')
        sys.exit(0)
#crear carpetas hmm13-15
    for x in range(13,16):
        fl.write('X: Creando hmm'+str(x)+'\n')
        if not os.path.isdir('hmm'+str(x)):
            try:
                os.system('mkdir hmm'+str(x))
            except:
                print 'ERROR41: No se ha podido crear la carpeta hmm'+str(x)
                fl.write('ERROR41: No se ha podido crear la carpeta hmm'+str(x)+'\n')
                sys.exit(0)
#ejecutar htk/HTKTools/HHEd -A -D -T 1 -H hmm12/macros -H hmm12/hmmdefs -M hmm13 tree.hed triphones1
    try:
        os.system('htk/HTKTools/HHEd -A -D -T 1 -H hmm12/macros -H hmm12/hmmdefs -M hmm13 tree.hed triphones1')
        fl.write('X: htk/HTKTools/HHEd -A -D -T 1 -H hmm12/macros -H hmm12/hmmdefs -M hmm13 tree.hed triphones1\n')
    except:
        print 'ERROR42: No se ha podido ejecutar htk/HTKTools/HHEd'
        fl.write('ERROR42: No se ha podido ejecutar htk/HTKTools/HHEd\n')
        sys.exit(0)
    if not os.path.isfile('tiedlist'):
        print 'ERROR42b: No se encuentra el archivo tiedlist'
        fl.write('ERROR42b: No se encuentra el archivo tiedlist\n')
        sys.exit(0)
#ejecutar htk/HTKTools/HERest -A -D -T 1 -T 1 -C config -I wintri.mlf  -t 250.0 150.0 3000.0 -S train.scp -H hmm13/macros -H hmm13/hmmdefs -M hmm14 tiedlist
    try:
        os.system('htk/HTKTools/HERest -A -D -T 1 -T 1 -C config -I wintri.mlf  -t 250.0 150.0 3000.0 -S train.scp -H hmm13/macros -H hmm13/hmmdefs -M hmm14 tiedlist')
        fl.write('X: htk/HTKTools/HERest -A -D -T 1 -T 1 -C config -I wintri.mlf  -t 250.0 150.0 3000.0 -S train.scp -H hmm13/macros -H hmm13/hmmdefs -M hmm14 tiedlist\n')
    except:
        print 'ERROR43: No se ha podido ejecutar htk/HTKTools/HERest'
        fl.write('ERROR43: No se ha podido ejecutar htk/HTKTools/HERest\n')
        sys.exit(0)
#ejecutar htk/HTKTools/HERest -A -D -T 1 -T 1 -C config -I wintri.mlf  -t 250.0 150.0 3000.0 -S train.scp -H hmm14/macros -H hmm14/hmmdefs -M hmm15 tiedlist
    try:
        os.system('htk/HTKTools/HERest -A -D -T 1 -T 1 -C config -I wintri.mlf  -t 250.0 150.0 3000.0 -S train.scp -H hmm14/macros -H hmm14/hmmdefs -M hmm15 tiedlist')
        fl.write('X: htk/HTKTools/HERest -A -D -T 1 -T 1 -C config -I wintri.mlf  -t 250.0 150.0 3000.0 -S train.scp -H hmm14/macros -H hmm14/hmmdefs -M hmm15 tiedlist\n')
    except:
        print 'ERROR44: No se ha podido ejecutar htk/HTKTools/HERest'
        fl.write('ERROR44: No se ha podido ejecutar htk/HTKTools/HERest\n')
        sys.exit(0)
#crear carpeta mljulius (modelo linguistico para julius)
    os.chdir('..')
    os.system('mkdir mljulius')
#crear carpeta modelo/hmm15
    os.system('mkdir mljulius/hmm15')
#copiar hmm15/hmmdefs a modelo/hmm15/hmmdefs
    os.system('cp con/hmm15/hmmdefs mljulius/hmm15')
#copiar sample.jconf a modelo
    os.system('cp con/sample.jconf mljulius')
#copiar sample.dict a modelo
    os.system('cp con/sample.dict mljulius')
#copiar sample.dfa a modelo
    os.system('cp con/sample.dfa mljulius')
#copiar tiedlist a modelo
    os.system('cp con/tiedlist mljulius')
#ejecutar julius -input mic -C sample.jconf
    print '##########################################################################'
    print '                   MODELO DE LENGUAJE CREADO EN mljulius'
    print '##########################################################################'
    print 'Para ejecutar julius:'
    print '       - Entre en la capreta mljulius'
    print '       - ejecute: julius -input mic -C sample.jconf'
    print '       - como servidor, ejecute: julius -input mic -C sample.jconf -module'

#    os.chdir('mljulius')
#    try:
#        os.system('julius -input mic -C sample.jconf')
#    except:
#        os.system('cat julius.log')

if __name__ == "__main__":
    check_execs('python','julius','julia')
    main()
