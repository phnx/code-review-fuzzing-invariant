import os
import pathlib
import json
from typing import List

from SATResult import SATResult


def read_result(result_filename: str) -> List[SATResult]:
    try:
        # lookup warning_rule_id mapping file
        weakness_mapping_path = (
            pathlib.Path(__file__).parent.resolve() / "weakness-mapping.json"
        )
        weakness_mapping = {}
        if os.path.isfile(weakness_mapping_path):
            mapping_file = open(weakness_mapping_path)
            weakness_mapping = json.load(mapping_file)
            mapping_file.close()

        with open(result_filename) as report_file:
            report = json.load(report_file)

            standard_results = []
            for result in report["reports"]:
                # standardize tool's result

                weakness_rule_id = ""
                if result["checker_name"] in weakness_mapping.keys():
                    weakness_rule_id = ",".join(
                        weakness_mapping[result["checker_name"]]
                    )
                else:
                    # print("unmapped weakness:", result["checker_name"])
                    pass

                # TODO map CodeChecker checker to weakness
                standard_result = SATResult(
                    location_hash=result["report_hash"],
                    location_file=result["file"]["path"],
                    location_start_line=result["line"],
                    location_start_column=result["column"],
                    location_end_line=result["line"],
                    location_end_column=result["column"],
                    warning_rule_id=result["checker_name"],
                    warning_rule_name=result["checker_name"],
                    warning_message=result["message"],
                    warning_weakness=weakness_rule_id,
                    warning_severity=result["severity"],  # MEDIUM, HIGH, LOW
                )

                standard_results.append(standard_result)

            return standard_results

    except Exception as ex:
        # in any cases of failure - flag down the execution
        print("codechecker handle exception", str(ex), result)
        return []
