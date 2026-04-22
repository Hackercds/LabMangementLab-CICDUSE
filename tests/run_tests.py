"""
实验室管理系统API自动化测试运行脚本
支持多种运行模式和报告生成
"""
import os
import sys
import subprocess
import argparse
import shutil
from datetime import datetime
from pathlib import Path


class TestRunner:
    """测试运行器"""
    
    def __init__(self):
        self.project_root = Path(__file__).parent
        self.test_dir = self.project_root / "tests"
        self.report_dir = self.project_root / "reports"
        self.allure_results = self.report_dir / "allure-results"
        self.allure_report = self.report_dir / "allure-report"
    
    def clean_reports(self):
        """清理旧的报告"""
        if self.allure_results.exists():
            shutil.rmtree(self.allure_results)
        if self.allure_report.exists():
            shutil.rmtree(self.allure_report)
        
        self.allure_results.mkdir(parents=True, exist_ok=True)
        print(f"✓ 已清理旧报告目录")
    
    def install_dependencies(self):
        """安装测试依赖"""
        print("正在安装测试依赖...")
        requirements_file = self.test_dir / "requirements.txt"
        
        result = subprocess.run(
            [sys.executable, "-m", "pip", "install", "-r", str(requirements_file)],
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            print("✓ 依赖安装成功")
        else:
            print(f"✗ 依赖安装失败: {result.stderr}")
            sys.exit(1)
    
    def run_smoke_tests(self):
        """运行冒烟测试"""
        print("\n" + "="*50)
        print("运行冒烟测试...")
        print("="*50)
        
        self.clean_reports()
        
        cmd = [
            "pytest",
            str(self.test_dir),
            "-m", "smoke",
            "-v",
            "--alluredir", str(self.allure_results),
            "--html", str(self.report_dir / "smoke-report.html"),
            "--self-contained-html"
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        print(result.stdout)
        
        if result.returncode == 0:
            print("\n✓ 冒烟测试通过")
        else:
            print("\n✗ 冒烟测试失败")
        
        return result.returncode
    
    def run_regression_tests(self):
        """运行回归测试"""
        print("\n" + "="*50)
        print("运行回归测试...")
        print("="*50)
        
        self.clean_reports()
        
        cmd = [
            "pytest",
            str(self.test_dir),
            "-v",
            "--alluredir", str(self.allure_results),
            "--html", str(self.report_dir / "regression-report.html"),
            "--self-contained-html",
            "--json-report",
            "--json-report-file", str(self.report_dir / "report.json")
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        print(result.stdout)
        
        if result.returncode == 0:
            print("\n✓ 回归测试通过")
        else:
            print("\n✗ 回归测试失败")
        
        return result.returncode
    
    def run_specific_module(self, module):
        """运行指定模块测试"""
        print(f"\n{'='*50}")
        print(f"运行{module}模块测试...")
        print("="*50)
        
        self.clean_reports()
        
        test_file = self.test_dir / f"test_{module}.py"
        if not test_file.exists():
            print(f"✗ 测试文件不存在: {test_file}")
            return 1
        
        cmd = [
            "pytest",
            str(test_file),
            "-v",
            "--alluredir", str(self.allure_results),
            "--html", str(self.report_dir / f"{module}-report.html"),
            "--self-contained-html"
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        print(result.stdout)
        
        return result.returncode
    
    def run_with_parallel(self, workers=4):
        """并行运行测试"""
        print(f"\n{'='*50}")
        print(f"并行运行测试 (workers={workers})...")
        print("="*50)
        
        self.clean_reports()
        
        cmd = [
            "pytest",
            str(self.test_dir),
            "-v",
            "-n", str(workers),
            "--alluredir", str(self.allure_results)
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        print(result.stdout)
        
        return result.returncode
    
    def run_failed_tests(self):
        """运行失败的测试"""
        print("\n" + "="*50)
        print("运行失败的测试...")
        print("="*50)
        
        cmd = [
            "pytest",
            str(self.test_dir),
            "--lf",
            "-v",
            "--alluredir", str(self.allure_results)
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        print(result.stdout)
        
        return result.returncode
    
    def generate_allure_report(self):
        """生成Allure报告"""
        print("\n" + "="*50)
        print("生成Allure测试报告...")
        print("="*50)
        
        if not self.allure_results.exists():
            print("✗ 没有测试结果数据")
            return 1
        
        cmd = [
            "allure",
            "generate",
            str(self.allure_results),
            "-o", str(self.allure_report),
            "--clean"
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            print(f"✓ Allure报告生成成功: {self.allure_report}")
            print(f"  打开报告: allure open {self.allure_report}")
        else:
            print(f"✗ Allure报告生成失败: {result.stderr}")
            print("  提示: 请确保已安装Allure命令行工具")
        
        return result.returncode
    
    def open_allure_report(self):
        """打开Allure报告"""
        cmd = ["allure", "open", str(self.allure_report)]
        subprocess.run(cmd)
    
    def run_full_test_suite(self):
        """运行完整测试套件"""
        print("\n" + "="*50)
        print("运行完整测试套件...")
        print("="*50)
        
        self.clean_reports()
        
        cmd = [
            "pytest",
            str(self.test_dir),
            "-v",
            "--alluredir", str(self.allure_results),
            "--html", str(self.report_dir / "full-report.html"),
            "--self-contained-html",
            "--json-report",
            "--json-report-file", str(self.report_dir / "full-report.json"),
            "--timeout=60",
            "--reruns=2",
            "--reruns-delay=1"
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        print(result.stdout)
        
        if result.returncode == 0:
            print("\n✓ 完整测试套件通过")
        else:
            print("\n✗ 完整测试套件失败")
        
        # 生成Allure报告
        self.generate_allure_report()
        
        return result.returncode


def main():
    """主函数"""
    parser = argparse.ArgumentParser(description="实验室管理系统API自动化测试")
    parser.add_argument(
        "command",
        choices=["install", "smoke", "regression", "full", "failed", "parallel", "module", "report", "open"],
        help="测试命令"
    )
    parser.add_argument(
        "--module",
        help="指定测试模块 (auth/reservation/lab/device/statistics)"
    )
    parser.add_argument(
        "--workers",
        type=int,
        default=4,
        help="并行测试的worker数量"
    )
    
    args = parser.parse_args()
    
    runner = TestRunner()
    
    if args.command == "install":
        runner.install_dependencies()
    
    elif args.command == "smoke":
        exit_code = runner.run_smoke_tests()
        runner.generate_allure_report()
        sys.exit(exit_code)
    
    elif args.command == "regression":
        exit_code = runner.run_regression_tests()
        runner.generate_allure_report()
        sys.exit(exit_code)
    
    elif args.command == "full":
        exit_code = runner.run_full_test_suite()
        sys.exit(exit_code)
    
    elif args.command == "failed":
        exit_code = runner.run_failed_tests()
        sys.exit(exit_code)
    
    elif args.command == "parallel":
        exit_code = runner.run_with_parallel(args.workers)
        runner.generate_allure_report()
        sys.exit(exit_code)
    
    elif args.command == "module":
        if not args.module:
            print("✗ 请指定测试模块: --module <module_name>")
            sys.exit(1)
        exit_code = runner.run_specific_module(args.module)
        runner.generate_allure_report()
        sys.exit(exit_code)
    
    elif args.command == "report":
        runner.generate_allure_report()
    
    elif args.command == "open":
        runner.open_allure_report()


if __name__ == "__main__":
    main()
