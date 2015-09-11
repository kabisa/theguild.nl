jobMessages =
  nl: """Ruby, Java of Frontend developer? Dan zoeken we jou!
Check onze vacatures: http://kabisa.nl/jobs."""
  en: """Ruby, Java or Frontend developer? Then we're looking for you!
Have a look at our jobs: http://kabisa.nl/jobs."""

lang = document.documentElement.lang

# generated with:
# convert logo2x.png -modulate 90 jpg:- | jp2a --height=15 --grayscale -
jobs = """
                                                       ,:cOk:
                                                     .kNXXXx.
                                                     ,NNNd.
                                                     .kNNNNX0kxdoc:,'.
                                                    .xKNNNNNNNNNNNNNNNKkl'
                                                    lNd..dKNNNXNNNNNNNNNNNO;
                        .kd.                        .O,    ...,NNO;...':dXNNk.
 'l,    .ll;   'cool:.  'NN0odoo:.   cl.   ;oddddddd. ..:ooo:..0k        .kNNx
 cNN:   lNNc ,0NXOk0NNk.'NNKkkk0NNk. ONK..KNK;;;;;x: 'ONXOkONNk,.         .KNN.
 cNNo,cONNd..XN0.   :NNk'NNk    ,XNO ONN..XN0xxxxd:..KNX'   'XNK. .o0OOk.  ONN.
 cNNNNK0NNc .XN0.   .XN0.KNK.   ,XNO ONN. .c;:;:;:NK'XNK'    ONN. lNo 'x' cNNo
 cNNl.  oNX: ,0NXOkkkNN0 'ONXOk0NNO. kNN. :xkkkkkXN0.'ONXOkkkXNN. .OXxlld0N0c
 'oo'    :oo.  'cooooool   'cooo:.   .:o..oooooooo;    .cooooooo.   .:lll:.

#{jobMessages[lang] || jobMessages['en']}
"""
window.console && console.log(jobs)
