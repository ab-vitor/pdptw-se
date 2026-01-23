from .entities import ParameterData

def parse(value: str) -> str:
    return value


def load_general_configuration(gen_config_file_path: str, params:ParameterData) -> None:
    # Create a dictionary with fields and their types.
    param_names_types = {
        name: typ for name, typ in zip(params.__dataclass_fields__.keys(), params.__dataclass_fields__.values())
    }

    param_given = {name: False for name in param_names_types.keys()}

    lines = []
    try:
        with open(gen_config_file_path, 'r') as file:
            lines = file.readlines()
    except Exception as err:
        raise RuntimeError(f"Cannot read '{gen_config_file_path}'") from err

    if len(lines) == 0:
        raise RuntimeError(f"Cannot read '{gen_config_file_path}'")

    for line_number, line in enumerate(lines, start=1):
        line = line.strip()
        if len(line) == 0 or line.startswith('#'):
            continue

        try:
            param_name, value = line.split()
            if param_name in param_names_types:
                field_type = param_names_types[param_name].type
                if field_type is bool:
                    parsed_value = value.lower() in ("true", "1", "yes", "on")
                elif field_type is str:
                    parsed_value = parse(value)
                else:
                    parsed_value = field_type(value)
                setattr(params, param_name, parsed_value)
                param_given[param_name] = True
                print(f"Parameter '{param_name}' with value '{value}' successfully set as {parsed_value} of type {type(parsed_value)}")
            else:
                raise KeyError(f"Parameter '{param_name}' unknown")

        except ValueError:
            raise RuntimeError(
                f"Error on line {line_number} of '{gen_config_file_path}': missing parameter or value"
            )
        except KeyError as err:
            raise RuntimeError(
                f"Error on line {line_number} of '{gen_config_file_path}': {err}"
            )
        except Exception as err:
            raise RuntimeError(
                f"Error on line {line_number} of '{gen_config_file_path}': invalid value for '{param_name}': {value}"
            ) from err

    return None