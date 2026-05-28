import importlib.util
from pathlib import Path


MODULE_PATH = Path(__file__).resolve().parents[1] / "src" / "software" / "reference_model.py"


def load_module():
    spec = importlib.util.spec_from_file_location("reference_model", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def test_quantized_matmul_basic():
    model = load_module()

    a = [[1, 2], [3, 4]]
    b = [[5, 6], [7, 8]]

    result = model.quantized_matmul(a, b)

    assert result == [[19, 22], [43, 50]]
