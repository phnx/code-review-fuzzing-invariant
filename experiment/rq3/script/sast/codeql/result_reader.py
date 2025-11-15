from typing import List

from sarif import loader

from SATResult import SATResult


def read_result(result_filename: str) -> List[SATResult]:
    # TODO update target trial result location when analyzing data
    try:
        result = loader.load_sarif_file(result_filename)

        raw_results = result.get_results()

        rules = result.data["runs"][0]["tool"]["driver"]["rules"]
        rule_name = {r["id"]: r["shortDescription"]["text"] for r in rules}
        rule_weaknesses = {
            r["id"]: ",".join(
                [
                    (t.split("/")[-1]).upper()
                    for t in r["properties"]["tags"]
                    if "/cwe/" in t
                ]
            )
            for r in rules
        }
        rule_severity = {r["id"]: r["defaultConfiguration"]["level"] for r in rules}

        # severity mapping
        severity_level = {
            "error": "HIGH",
            "warning": "MEDIUM",
            "note": "LOW",
        }

        standard_results = []
        for result in raw_results:
            # standardize tool's result
            # get right results from SARIF - ensure that columns exist
            start_line = (
                result["locations"][0]["physicalLocation"]
                .get("region", {})
                .get("startLine", -1)
            )

            start_column = (
                result["locations"][0]["physicalLocation"]
                .get("region", {})
                .get("startColumn", -1)
            )
            end_line = (
                result["locations"][0]["physicalLocation"]
                .get("region", {})
                .get("endLine", -1)
            )
            end_column = (
                result["locations"][0]["physicalLocation"]
                .get("region", {})
                .get("endColumn", -1)
            )

            standard_result = SATResult(
                location_hash=result["partialFingerprints"]["primaryLocationLineHash"],
                location_file=result["locations"][0]["physicalLocation"][
                    "artifactLocation"
                ]["uri"],
                location_start_line=start_line,
                location_start_column=start_column,
                location_end_line=end_line,
                location_end_column=end_column,
                warning_rule_id=result["ruleId"],
                warning_rule_name=rule_name[result["ruleId"]],
                warning_message=result["message"]["text"],
                warning_weakness=rule_weaknesses[result["ruleId"]],
                warning_severity=severity_level[
                    str(rule_severity[result["ruleId"]]).lower()
                ],  # convert error, warning, note to HIGH, MEDIUM, LOW
            )

            standard_results.append(standard_result)

        return standard_results

    except Exception as ex:
        # in any cases of failure - flag down the execution
        print("codeql handle exception", str(ex), result)
        return []
