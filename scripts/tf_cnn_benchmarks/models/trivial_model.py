# Copyright 2017 The TensorFlow Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================
"""Trivial model configuration."""

from models import model


class TrivialModel(model.CNNModel):
  """Trivial model configuration."""

  def __init__(self, params=None):
    super(TrivialModel, self).__init__(
        'trivial', 224 + 3, 32, 0.005, params=params)

  def add_inference(self, cnn):
    cnn.reshape([-1, 227 * 227 * 3])
    cnn.affine(1)
    cnn.affine(4096)


class TrivialCifar10Model(model.CNNModel):
  """Trivial cifar10 model configuration."""

  def __init__(self, params=None):
    super(TrivialCifar10Model, self).__init__(
        'trivial', 32, 32, 0.005, params=params)

  def add_inference(self, cnn):
    cnn.reshape([-1, 32 * 32 * 3])
    cnn.affine(1)
    cnn.affine(4096)

class AndrewTrivialModel(model.CNNModel):
  """Trivial model configuration."""

  def __init__(self, params=None):
    super(AndrewTrivialModel, self).__init__(
        'andrew_trivial', 224 + 3, 32, 0.005, params=params)

  def add_inference(self, cnn):
    cnn.reshape([-1, 227 * 227 * 3])
    # Target model size = 104MB to match ResNet-50
    # (104 * 1024 * 1024 / 4 - 4096) / (227 * 227 * 3 + 4096 + 1) = 172
    cnn.affine(172)
    cnn.affine(4096)

class TinyCifar10Model(model.CNNModel):
  """Trivial cifar10 model configuration."""

  def __init__(self, params=None):
    super(TinyCifar10Model, self).__init__(
        'tiny_trivial', 32, 32, 0.005, params=params)

  def add_inference(self, cnn):
    cnn.reshape([-1, 32 * 32 * 3])
    cnn.affine(1)

