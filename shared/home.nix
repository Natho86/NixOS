{ config, pkgs, ... }:

{
  home.username = "nath";
  home.homeDirectory = "/home/nath";

  # This value determines the Home Manager release
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Packages to install
  home.packages = with pkgs; [
    # Browsers
    google-chrome
    
    # Communication
    signal-desktop
    #whatsapp-for-linux
    
    # Media
    #audacity.override { ffmpeg = pkgs.ffmpeg_6-full; }
    spotify
    
    # Productivity
    obsidian
    
    # Development
    docker-compose
    github-desktop
    vscode
    nmap
    
    # Terminal utilities
    neofetch
    tmux
    tree

    # System utilities
    jq              # JSON processor
    yq-go           # YAML processor
    tldr            # Simplified man pages
    ncdu            # Disk usage analyzer (ncurses)
    duf             # Modern df alternative
    procs           # Modern ps alternative
    dust            # Modern du alternative
    bottom          # System monitor (btop alternative)
    bandwhich       # Network utilization monitor

    # Network utilities
    httpie          # User-friendly HTTP client
    rsync           # File sync utility
    mtr             # Network diagnostic tool
    iperf3          # Network performance testing
    tcpdump         # Packet analyzer

    # System debugging
    strace          # System call tracer
    lsof            # List open files
    pciutils        # PCI utilities (already in system packages, but useful here too)

    # Fonts
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.hack
    noto-fonts
    noto-fonts-color-emoji
    font-awesome

  ];

  # Alacritty - Modern terminal emulator
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        opacity = 0.95;
        padding = {
          x = 10;
          y = 10;
        };
        decorations = "full";
      };
      
      font = {
        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular";
        };
        bold = {
          family = "JetBrainsMono Nerd Font";
          style = "Bold";
        };
        italic = {
          family = "JetBrainsMono Nerd Font";
          style = "Italic";
        };
        size = 11.0;
      };
      
      colors = {
        primary = {
          background = "#1e1e2e";
          foreground = "#cdd6f4";
        };
        cursor = {
          text = "#1e1e2e";
          cursor = "#f5e0dc";
        };
        normal = {
          black = "#45475a";
          red = "#f38ba8";
          green = "#a6e3a1";
          yellow = "#f9e2af";
          blue = "#89b4fa";
          magenta = "#f5c2e7";
          cyan = "#94e2d5";
          white = "#bac2de";
        };
        bright = {
          black = "#585b70";
          red = "#f38ba8";
          green = "#a6e3a1";
          yellow = "#f9e2af";
          blue = "#89b4fa";
          magenta = "#f5c2e7";
          cyan = "#94e2d5";
          white = "#a6adc8";
        };
      };
      
      cursor = {
        style = "Block";
        unfocused_hollow = true;
      };
    };
  };

  # Neovim configuration
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    
    plugins = with pkgs.vimPlugins; [
      # Theme
      catppuccin-nvim
      
      # Essential plugins
      telescope-nvim
      nvim-treesitter.withAllGrammars
      nvim-lspconfig
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      luasnip
      
      # File explorer
      nvim-tree-lua
      nvim-web-devicons
      
      # Status line
      lualine-nvim
      
      # Git integration
      gitsigns-nvim
      vim-fugitive
      
      # Utilities
      comment-nvim
      nvim-autopairs
      indent-blankline-nvim
      which-key-nvim
    ];
    
    extraLuaConfig = ''
      -- Basic settings
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.expandtab = true
      vim.opt.shiftwidth = 2
      vim.opt.tabstop = 2
      vim.opt.smartindent = true
      vim.opt.wrap = false
      vim.opt.swapfile = false
      vim.opt.backup = false
      vim.opt.undofile = true
      vim.opt.hlsearch = false
      vim.opt.incsearch = true
      vim.opt.termguicolors = true
      vim.opt.scrolloff = 8
      vim.opt.signcolumn = "yes"
      vim.opt.updatetime = 50
      vim.opt.colorcolumn = "80"
      
      -- Leader key
      vim.g.mapleader = " "
      
      -- Catppuccin theme
      require("catppuccin").setup({
        flavour = "mocha",
        transparent_background = false,
      })
      vim.cmd.colorscheme "catppuccin"
      
      -- Lualine
      require('lualine').setup {
        options = {
          theme = 'catppuccin',
          icons_enabled = true,
        }
      }
      
      -- Nvim-tree
      require("nvim-tree").setup()
      vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { silent = true })
      
      -- Telescope
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
      vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
      
      -- Treesitter
      require('nvim-treesitter.configs').setup {
        highlight = { enable = true },
        indent = { enable = true },
      }
      
      -- LSP
      local lspconfig = require('lspconfig')
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      
      -- Setup completion
      local cmp = require('cmp')
      cmp.setup({
        snippet = {
          expand = function(args)
            require('luasnip').lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'buffer' },
          { name = 'path' },
        })
      })
      
      -- Gitsigns
      require('gitsigns').setup()
      
      -- Comment
      require('Comment').setup()
      
      -- Autopairs
      require('nvim-autopairs').setup()
      
      -- Which-key
      require('which-key').setup()
      
      -- Indent blankline
      require('ibl').setup()
    '';
  };

  # Git configuration
  programs.git = {
    enable = true;
    settings = {
      user.name = "Natho86";
      user.email = "oakes.nathan@gmail.com";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      credential.helper = "libsecret";
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      syntax-theme = "base16";
    };
  };

  # Zsh configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    shellAliases = {
      ll = "eza -l --icons";
      la = "eza -la --icons";
      ls = "eza --icons";
      cat = "bat";
      
      # NixOS specific
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config#laptop";
      update = "nix flake update ~/nixos-config && sudo nixos-rebuild switch --flake ~/nixos-config#laptop";
      clean = "sudo nix-collect-garbage -d";
      
      # Git shortcuts
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline --graph";
    };
    
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "git"
        "docker"
        "docker-compose"
        "sudo"
        "history"
        "colored-man-pages"
      ];
    };
    
    initContent = ''
      # Starship prompt
      eval "$(starship init zsh)"
      
      # FZF keybindings
      source ${pkgs.fzf}/share/fzf/key-bindings.zsh
      source ${pkgs.fzf}/share/fzf/completion.zsh
    '';
  };

  # Starship prompt
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
      package.disabled = true;
    };
  };

  # Btop configuration
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "Default";
      theme_background = false;
      vim_keys = true;
    };
  };

  # bat config
  programs.bat = {
    enable = true;
    config = {
      theme = "base16";
    };
  };

  # Fonts
  fonts.fontconfig.enable = true;

  # Qtile configuration
  xdg.configFile."qtile/config.py".source = ./qtile-config.py;

  # GTK theme
  gtk = {
    enable = true;
    theme = {
      name = "Catppuccin-Mocha-Standard-Blue-Dark";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "blue" ];
        variant = "mocha";
      };
    };
    
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    
    cursorTheme = {
      name = "Catppuccin-Mocha-Dark-Cursors";
      package = pkgs.catppuccin-cursors.mochaDark;
    };
  };

  # Qt theme
  qt = {
    enable = true;
    platformTheme.name = "kde";
    #style.name = "kvantum";
  };

  #home.file.".config/Kvantum/kvantum.kvconfig".text = ''
  #  [General]
  #  theme=Catppuccin-Mocha-Blue
  #'';
}
