"""Reproducible original synthesis, standard library only. No external audio samples."""
import math, random, struct, wave
from pathlib import Path
ROOT = Path(__file__).parent
RATE = 22050
random.seed(25)

def save(name, duration, synth):
    samples = [max(-1, min(1, synth(i/RATE, i))) for i in range(int(duration*RATE))]
    with wave.open(str(ROOT / (name+'.wav')), 'wb') as f:
        f.setparams((1,2,RATE,len(samples),'NONE','not compressed'))
        f.writeframes(b''.join(struct.pack('<h',int(x*24000)) for x in samples))

def tone(name, freq, duration, slide=0, noise=0, volume=.35):
    save(name,duration,lambda t,i: volume*(math.sin(2*math.pi*(freq*t+slide*t*t))+noise*random.uniform(-1,1))*(1-t/duration)**2*min(1,t/.004))

tone('swing',190,.12,-600,.5,.2)
tone('hit',100,.09,-350,.7,.3)
tone('hurt',140,.25,-150,.3,.35)
tone('death',190,.15,-500,.3,.22)
tone('roll',310,.15,-700,.15,.15)
tone('cast',340,.18,320,.1,.2)
tone('boss',62,.9,-15,.1,.45)
for name,notes in [('heal',[440,660]),('reward',[330,440,660]),('victory',[262,330,392,523,660]),('loss',[220,196,147,110])]:
    duration=len(notes)*.16
    save(name,duration,lambda t,i,n=notes: .24*math.sin(2*math.pi*n[min(len(n)-1,int(t/.16))]*t)*(1-(t%.16)/.16))
# Sixteen second minor arpeggio, sparse bells and a quiet low drone; seamless envelope.
def music(t,i):
    notes=[146.83,174.61,220,261.63,130.81,174.61,196,261.63,164.81,196,246.94,293.66,146.83,174.61,220,329.63]
    note=notes[int(t)%16]; age=t%1
    bell=(math.sin(2*math.pi*note*t)+.3*math.sin(2*math.pi*note*2*t))*.16*math.exp(-age*4)*min(1,age/.01)
    drone=.07*math.sin(2*math.pi*55*t)+.04*math.sin(2*math.pi*110*t)
    return (bell+drone)*min(1,t/.1,(16-t)/.1)
save('vigil',16,music)
