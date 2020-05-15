
from abc import ABCMeta, abstractmethod

class Observer(metaclass=ABCMeta):
    @abstractmethod
    def on_next(self, item):
        pass

    @abstractmethod
    def on_compile(self, root, p4_program, ingress_egress_flag, parent_type):
        pass

    #@abstractmethod
    def on_complete(self):
        pass

class Observable(object):
    def __init__(self):
        self.observers = list()
        self.complete = False

    def subscribe(self, observer):
        if not isinstance(observer, Observer):
            raise ValueError("Only Observer objects are valid subscribers")
        self.observers.append(observer)

    def _notify_next(self, item):
        print("%s go _next" % str(self))
        if self.complete:
            raise RuntimeError("Completed")
        for obs in self.observers:
            obs.on_next(item)


    def _notify_complete(self):
        if self.complete:
            raise RuntimeError("Already Completed")
        self.complete = True
        for obs in self.observers:
            obs.on_complete()

    def _notify_compile(self, root, p4_program, parent_type):
        print("%s" % str(self))
        print(); print()
        if self.complete:
            raise RuntimeError("Completed")
        for obs in self.observers:
            obs.on_compile(root, p4_program, parent_type)
