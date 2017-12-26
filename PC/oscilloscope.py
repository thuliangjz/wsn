import serial, socket, sys
from pyqtgraph.Qt import QtGui, QtCore
import pyqtgraph as pg
import numpy as np
import signal
import sys
import tos

AM_OSCILLOSCOPE = 0x30
am = tos.AM()

class OscilloscopeMsg(tos.Packet):
    def __init__(self, packet = None):
        tos.Packet.__init__(self,
                            [('id', 'int', 16),
                             ('seq', 'int', 16),
                             ('humidity', 'int', 16),
                             ('light', 'int', 16),
                             ('temperature', 'int', 16),
                             ('timestamp', 'int', 32)],
                            packet)

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

    def handle_close_event(self, event):
        self.app.exit()

    def plot_init(self):
        trial_data = ['0', '0', '0']
        for i in range(len(trial_data)):
            new_plot = self.layout.addPlot()
            new_plot.plot(np.zeros(250))
            self.plot_list.append(new_plot.listDataItems()[0])
            self.layout.nextRow()
        
    def update(self):
        p = am.read()
        if p and p.type == AM_OSCILLOSCOPE:
            msg = OscilloscopeMsg(p.data)
            stream_data = []
            stream_data.append(str(msg.temperature))
            stream_data.append(str(msg.humidity))
            stream_data.append(str(msg.light))
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
 
    def start(self):
        self.plot_init()
        timer = QtCore.QTimer()
        timer.timeout.connect(self.update)
        timer.start(0)   
        if (sys.flags.interactive != 1) or not hasattr(QtCore, 'PYQT_VERSION'):
            self.app.exec_()   

plot = BasePlot()
plot.start()