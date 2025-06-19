from abc import ABC, abstractmethod


# example of an abstract base class for a machine learning model

class BaseMlModel(ABC):
    def __init__(self, model_name: str):
        self.model_name = model_name

    @abstractmethod
    def train(self, data):
        raise NotImplementedError("Subclasses should implement this method")

    @abstractmethod
    def predict(self, data):
        raise NotImplementedError("Subclasses should implement this method")

    @abstractmethod
    def evaluate(self, predictions, ground_truth):
        raise NotImplementedError("Subclasses should implement this method")