package socks5

import (
	"net/url"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestParse(t *testing.T) {
	tests := []struct {
		name     string
		rawURL   string
		wantAddr string
		wantUser string
		wantPass string
		wantErr  bool
	}{
		{
			name:     "standard",
			rawURL:   "socks5://127.0.0.1:1080",
			wantAddr: "127.0.0.1:1080",
		},
		{
			name:     "with auth",
			rawURL:   "socks5://user:pass@example.com:1080",
			wantAddr: "example.com:1080",
			wantUser: "user",
			wantPass: "pass",
		},
		{
			name:     "user only",
			rawURL:   "socks5://user@example.com:1080",
			wantAddr: "example.com:1080",
			wantUser: "user",
		},
		{
			name:     "unix domain socket",
			rawURL:   "socks5:///tmp/socks.sock",
			wantAddr: "/tmp/socks.sock",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			u, err := url.Parse(tt.rawURL)
			require.NoError(t, err)

			p, err := Parse(u)
			if tt.wantErr {
				assert.Error(t, err)
				return
			}
			require.NoError(t, err)

			s5, ok := p.(*Socks5)
			require.True(t, ok, "proxy should be of type *Socks5")

			assert.Equal(t, tt.wantAddr, s5.addr)
			assert.Equal(t, tt.wantUser, s5.user)
			assert.Equal(t, tt.wantPass, s5.pass)
		})
	}
}
