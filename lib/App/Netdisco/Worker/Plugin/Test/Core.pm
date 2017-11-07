package App::Netdisco::Worker::Plugin::Test::Core;

use Dancer ':syntax';
use App::Netdisco::Worker::Plugin;
use aliased 'App::Netdisco::Worker::Status';

register_worker({ phase => 'early' }, sub {
  my ($job, $workerconf) = @_;
  return Status->error('Test (early) ran successfully.');
});

register_worker({ phase => 'early' }, sub {
  my ($job, $workerconf) = @_;
  return Status->done('Test (early) ran successfully.');
});

register_worker({ phase => 'main' }, sub {
  my ($job, $workerconf) = @_;
  return Status->done('Test (main) ran successfully (1).');
});

register_worker({ phase => 'main' }, sub {
  my ($job, $workerconf) = @_;
  return Status->done('Test (main) ran successfully (2).');
});

register_worker(sub {
  my ($job, $workerconf) = @_;
  return Status->noop('Test (user) ran successfully.');
});

register_worker(sub {
  my ($job, $workerconf) = @_;
  return Status->error('Test (user) ran successfully.');
});

true;
