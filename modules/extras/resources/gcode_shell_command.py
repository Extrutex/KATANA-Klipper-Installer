# gcode_shell_command.py - Bundled for KATANA (Source: Klipper Community)
import sys
import os
import subprocess
import shlex
import logging

class ShellCommand:
    def __init__(self, config):
        self.printer = config.get_printer()
        self.name = config.get_name().split()[-1]
        self.command = config.get("command")
        self.timeout = config.getfloat("timeout", 2., minval=0.)
        self.verbose = config.getboolean("verbose", True)
        self.gcode = self.printer.lookup_object('gcode')
        self.gcode.register_mux_command("RUN_SHELL_COMMAND", "CMD",
                                        self.name, self.cmd_RUN_SHELL_COMMAND,
                                        desc=self.cmd_RUN_SHELL_COMMAND_help)

    cmd_RUN_SHELL_COMMAND_help = "Run a configurable shell command"
    def cmd_RUN_SHELL_COMMAND(self, gcmd):
        params = gcmd.get_command_parameters()
        cmd_params = shlex.split(params.get('PARAMS', ''))
        cmd = shlex.split(self.command)
        cmd.extend(cmd_params)
        
        if self.verbose:
            self.gcode.respond_info("Running Command: %s" % (cmd))

        try:
            proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            stdout, stderr = proc.communicate(timeout=self.timeout)
        except subprocess.TimeoutExpired:
            self.gcode.respond_error("Command timeout")
            return
        except Exception as e:
            self.gcode.respond_error("Command error: %s" % (str(e)))
            return

        if self.verbose:
            if stdout:
                self.gcode.respond_info(stdout.decode('utf-8'))
            if stderr:
                self.gcode.respond_info(stderr.decode('utf-8'))

def load_config(config):
    return ShellCommand(config)
