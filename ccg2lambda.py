from subprocess import run


cp = run(["python", "scripts/semparse.py",
          "jsem_001_generalized_quantifier.txt.xml",
          "ja/semantic_templates_ja_emnlp2016.yaml",
          "jsem_001_generalized_quantifier.txt.sem.xml", "--arbi-types"],
         capture_output=True)
print("stdout:")
print(cp.stdout.decode())
if cp.stderr.decode() != "":
    print("stderr: ", cp.stderr.decode())
