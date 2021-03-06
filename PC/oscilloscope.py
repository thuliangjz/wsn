import serial, socket, sys
from pyqtgraph.Qt import QtGui, QtCore
import pyqtgraph as pg
import numpy as np
import signal
import sys
import tos
import threading
import time

AM_OSCILLOSCOPE = 0x30
am = tos.AM()
stream_data = ['0', '0', '0', '0', '0', '0']
file = open('result.txt', 'w')

class OscilloscopeMsg(tos.Packet):
    def __init__(self, packet = None):
        tos.Packet.__init__(self,
                            [('id', 'int', 2),
                             ('seq', 'int', 2),
                             ('humidity', 'int', 2),
                             ('light', 'int', 2),
                             ('temperature', 'int', 2),
                             ('timestamp', 'int', 4)],
                            packet)

class TimerMsg(tos.Packet):
    def __init__(self, packet = None):
        tos.Packet.__init__(self, [('time', 'int', 4)], packet)

class BasePlot(object):
    def __init__(self, **kwargs):
        try:
            self.app = QtGui.QApplication([])
        except RuntimeError:
            self.app = QtGui.QApplication.instance()
        self.view = pg.GraphicsView()
        self.layout = pg.GraphicsLayout(border=(100,100,100))
        self.view.closeEvent = self.handle_close_event
        self.layout.closeEvent = self.handle_close_event
        self.view.setCentralItem(self.layout)
        self.view.show()
        self.view.setWindowTitle('Software Oscilloscope')
        self.view.resize(800,600)
        self.plot_list = []
        self.start_time = time.time()
        self.end_time = 0
        self.last_id = 0
        self.last_seq = 0
        self.count = 0

    def handle_close_event(self, event):
        self.app.exit()

    def plot_init(self):
        for i in range(len(stream_data)):
            new_plot = self.layout.addPlot()
            new_plot.plot(np.zeros(250))
            self.plot_list.append(new_plot.listDataItems()[0])
            self.layout.nextRow()
        
    def update(self):
        p = am.read()
        if p and p.type == AM_OSCILLOSCOPE:
            msg = OscilloscopeMsg(p.data)
            if msg.id != self.last_id:
                self.count += 1
                if self.count == 2:
                    self.count = 0
                    self.end_time = time.time()
                    self.view.setWindowTitle('Software Oscilloscope - period:' + format((self.end_time - self.start_time), '0.3f') + 's')
                    self.start_time = self.end_time
            if msg.id == 100:
                stream_data[0] = str(msg.temperature)
                stream_data[1] = str(msg.humidity)
                stream_data[2] = str(msg.light)
            else:
                stream_data[3] = str(msg.temperature)
                stream_data[4] = str(msg.humidity)
                stream_data[5] = str(msg.light)
            if msg.id != self.last_id and msg.seq != self.last_seq:
                file.write(str(msg.id) + ' ' + str(msg.seq) + ' ' + str(msg.temperature) + ' ' + str(msg.humidity) + ' ' + str(msg.light) + ' ' + str(msg.timestamp) + '\n')
                self.last_id = msg.id
                self.last_seq = msg.seq
        for data, line in zip(stream_data, self.plot_list):
            line.informViewBoundsChanged()
            line.xData = np.arange(len(line.yData))
            line.yData = np.roll(line.yData, -1)
            line.yData[-1] = data
            line.xClean = line.yClean = None
            line.xDisp = None
            line.yDisp = None
            line.updateItems()
            line.sigPlotChanged.emit(line)
    
    def changePeriod(self):
        while True:
            period = input('Please enter new period:')
            new_packet = TimerMsg()
            new_packet.time = int(period)
            am.write(new_packet, 0x30)
 
    def start(self):
        self.plot_init()
        t1 = threading.Thread(target=self.changePeriod)
        t1.start()
        timer = QtCore.QTimer()
        timer.timeout.connect(self.update)
        timer.start(0)   
        if (sys.flags.interactive != 1) or not hasattr(QtCore, 'PYQT_VERSION'):
            self.app.exec_()

plot = BasePlot()
plot.start()