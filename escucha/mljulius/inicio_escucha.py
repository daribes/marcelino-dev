#!/usr/bin/env python
# -*- codding: utf-8 -*-

import os

print 'Servicio julius iniciado...'
os.system('julius -input mic -C modelo/sample.jconf -module')
