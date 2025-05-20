package options

import (
	"github.com/spf13/pflag"
)

type Options struct {
	test	interface{}
}

func NewOptions() *Options {
	return &Options{}
}

func (o *Options) AddFalgs(fs *pflag.FlagSet) {
	if o == nil {
		return
	}
}