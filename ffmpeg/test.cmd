# show text in the interval 5-10
5.0-10.0 [enter] drawtext reinit 'fontsize=56:fontcolor=green:fontfile=FreeSerif.ttf:text=hello world',
         [leave] drawtext reinit 'fontfile=FreeSerif.ttf:text=';

# desaturate the image in the interval 10-15
10.0-15.0 [enter] hue s 0,
          [enter] drawtext reinit 'fontfile=FreeSerif.ttf:text=nocolor',
          [leave] hue s 1,
          [leave] drawtext reinit 'fontfile=FreeSerif.ttf:text=color';

# apply an exponential saturation fade-out effect, starting from time 15
15 [enter] hue s exp(15-t)
