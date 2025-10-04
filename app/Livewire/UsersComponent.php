<?php

namespace App\Livewire;

use Livewire\Component;
use App\Models\User;

class UsersComponent extends Component
{
    public $title;
    public $email;
    public $password;
    public $name;
    public $buscar;
    public function render()
    {
        $this->title = "Usuarios";
        $users_count = User::count();
        $registros = User::all()->reverse();
        $registros_buscar = User::where("name","like","%".$this->buscar."%")->get();

        return view('livewire.users-component',[
            'title'=> $this->title,
            'users_count'=> $users_count,
            'registros' => $registros_buscar
        ]);
    }

    public function click() {
        dump("click");
    }
    public function crear_usuario() {
        //dump("crear_usuario");
        $this->validate([
            "name"=> "required|min:5|max:255",
            "email"=> "required|email|unique:users,email",
            "password"=> "required|min:5"
        ]);
        User::create([
            "name"=> $this->name,
            "email"=> $this->email,
            "password"=> $this->password
        ]);
    }
}
