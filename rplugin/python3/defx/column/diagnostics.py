import typing
import subprocess
import json
from defx.base.column import Base
from defx.context import Context
from neovim import Nvim
from functools import cmp_to_key

class Column(Base):

    def __init__(self, vim: Nvim) -> None:
        super().__init__(vim)

        self.name = 'diagnostics'
        self.current_cwd = ''
        self.cache = []

    def length(self, context: Context) -> int:
        return 1

    def get(self, context: Context, candidate: dict) -> str:
        if candidate.get('is_root', False):
            self.caching(candidate)
            return ' '

        for diagnostic in self.cache:
            if diagnostic.startswith(str(candidate['action__path'])):
                return '!'
        return ' '

    def caching(self, candidate: dict):
        definition = self.vim.call('defx_diagnostics#find', str(candidate['action__path']))
        if 'name' not in definition:
            return

        if self.current_cwd is definition['cwd']:
            return
        self.current_cwd = definition['cwd']

        self.cache = self.vim.call(
            'g:defx_diagnostics#parse',
            definition,
            self.run_cmd(definition['cmd'], definition['cwd'])
        )

    def run_cmd(self, cmd, cwd) -> str:
        try:
            self.vim.out_write(json.dumps(cwd))
            self.vim.out_write(json.dumps(cmd))
            p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=cwd)
        except subprocess.CalledProcessError:
            return ''

        decoded = p.stdout.decode('utf-8')

        if not decoded:
            return ''

        return decoded.strip('\n')


