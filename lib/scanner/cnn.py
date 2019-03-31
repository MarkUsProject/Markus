from __future__ import print_function
import torch
import torch.nn as nn
import torch.nn.functional as F
from torchvision import datasets, transforms


TRANSFORM = transforms.Compose([
        transforms.Grayscale(num_output_channels=1),
        transforms.ToTensor(),
        transforms.Normalize((0.1307,), (0.3081,))
    ])


class Net(nn.Module):
    """
    Neural network architecture for reading handwritten characters.
    """
    def __init__(self, num_output):
        super(Net, self).__init__()
        self.conv1 = nn.Conv2d(1, 20, 5, 1)
        self.conv2 = nn.Conv2d(20, 50, 5, 1)
        self.fc1 = nn.Linear(4 * 4 * 50, 500)
        self.fc2 = nn.Linear(500, num_output)

    def forward(self, x):
        x = F.relu(self.conv1(x))
        x = F.max_pool2d(x, 2, 2)
        x = F.relu(self.conv2(x))
        x = F.max_pool2d(x, 2, 2)
        x = x.view(-1, 4 * 4 * 50)
        x = F.relu(self.fc1(x))
        x = self.fc2(x)
        return F.log_softmax(x, dim=1)


def numeric_model():
    model = Net(10)
    model.load_state_dict(torch.load('/home/vagrant/Markus/lib/scanner/mnist_cnn.pt'))
    return model


def char_model():
    model = Net(26)
    model.load_state_dict(torch.load('/home/vagrant/Markus/lib/scanner/emnist_cnn.pt'))
    return model


def get_num(spaces):
    model = numeric_model()
    test_data = datasets.ImageFolder('/home/vagrant/Markus/lib/scanner/nums', transform=TRANSFORM)

    out = ""
    for images, labels in test_data:
        images = images.unsqueeze(0)
        output = model(images)
        pred = output.argmax(dim=1, keepdim=True)
        out += str(pred.data[0].item())

    print(insert_spaces(out, spaces))


def get_name(spaces):
    model = char_model()
    test_data = datasets.ImageFolder('/home/vagrant/Markus/lib/scanner/names', transform=TRANSFORM)

    out = ""
    for images, labels in test_data:
        images = images.unsqueeze(0)
        output = model(images)
        pred = output.argmax(dim=1, keepdim=True)
        out += chr(pred.data[0].item() + 97)

    print(insert_spaces(out, spaces).upper())


def insert_spaces(out, spaces):
    for s in spaces:
        out = out[:s - 1] + " " + out[s - 1:]
    return out.strip()
