def next_q(q,rst,en,d):
    if rst: return 0
    if en: return d
    return q

def run():
    q=0
    q=next_q(q,1,0,0xA5); assert q==0
    q=next_q(q,0,1,0x3C); assert q==0x3C
    q=next_q(q,0,0,0xF0); assert q==0x3C
    q=next_q(q,0,1,0xF0); assert q==0xF0
    q=next_q(q,1,1,0x55); assert q==0
    q=next_q(q,0,0,0xAA); assert q==0
    q=next_q(q,0,1,0xAA); assert q==0xAA
    print("A08 independent Python model: PASS")

if __name__=="__main__":
    run()
