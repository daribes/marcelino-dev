#!/usr/bin/env python
# -*- codding: utf-8 -*-

import os

# Script para generar los archivos prompts.txt codetrain.scp train.scp
# con los archivos de muestra generados con el entrenador

if not os.path.isdir('generados'):
    os.system('mkdir generados')
a_frases = open('generados/prompts.txt','w')
nmuestra = 0
if os.path.isdir('train/wav'):
    for archivo in os.listdir('train/wav'):
        if (archivo != '.') or (archivo != '..'):
            narchivo = archivo[:-4]
            if archivo[len(archivo)-3:] == 'txt':
                fr = open('train/wav/'+archivo,'r')
                for linea in fr.xreadlines():
                    U = linea.decode('utf8')
                    UM = U.upper()
                    linea = UM.encode('utf8')
                    a_frases.write('*/'+narchivo+' '+linea)
                fr.close()
a_frases.close()
print 'Archivo prompts.txt generado'
a_codetrain = open('generados/codetrain.scp','w')
a_train = open ('generados/train.scp','w')
if os.path.isdir('train/wav'):
    for archivo in os.listdir('train/wav'):
        if (archivo != '.') or (archivo != '..'):
            narchivo = archivo[:-4]
            if archivo[len(archivo)-3:] == 'wav':
                a_codetrain.write('train/wav/'+archivo+' train/mfcc/'+narchivo+'.mfc\n')
                a_train.write('train/mfcc/'+narchivo+'.mfc\n')
a_train.close()
a_codetrain.close()
print 'Archivos train.scp y codetrain.spc generados'
